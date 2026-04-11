import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../services/incident_service.dart';
import '../../models/incident.dart';

class CampusMapScreen extends StatefulWidget {
  const CampusMapScreen({super.key});

  @override
  State<CampusMapScreen> createState() => _CampusMapScreenState();
}

class _CampusMapScreenState extends State<CampusMapScreen> {
  final _incidentService = IncidentService();
  final MapController _mapController = MapController();

  // Default location (Nile University of Nigeria)
  LatLng _currentLocation = const LatLng(9.0298, 7.4332);
  bool _isLoading = true;
  List<Incident> _incidents = [];

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    await _getCurrentLocation();
    await _loadIncidents();
    setState(() => _isLoading = false);
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      if (permission == LocationPermission.deniedForever) return;

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
        });
        _mapController.move(_currentLocation, 15);
      }
    } catch (e) {
      // Location unavailable, keep default campus coordinates
    }
  }

  Future<void> _loadIncidents() async {
    final incidents = await _incidentService.getActiveIncidents();
    // Filter out incidents without location data
    setState(() {
      _incidents = incidents.where((i) => i.x != null && i.y != null).toList();
    });
  }

  Color _getSeverityColor(IncidentSeverity severity) {
    switch (severity) {
      case IncidentSeverity.critical: return AppColors.critical;
      case IncidentSeverity.high: return AppColors.warning;
      case IncidentSeverity.medium: return AppColors.secondary;
      case IncidentSeverity.low: return AppColors.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation,
              initialZoom: 15.0,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.safecampus.app',
                // Using standard OSM style which is free and clean
              ),

              // Incident Markers
              MarkerLayer(
                markers: _incidents.map((incident) {
                  return Marker(
                    point: LatLng(incident.x!, incident.y!),
                    width: 40,
                    height: 40,
                    child: GestureDetector(
                      onTap: () => _showIncidentDetails(incident),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _getSeverityColor(incident.severity).withOpacity(0.9),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: _getSeverityColor(incident.severity).withOpacity(0.5),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Icon(
                          _getIconForType(incident.type),
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              // User Location Marker
              MarkerLayer(
                markers: [
                  Marker(
                    point: _currentLocation,
                    width: 60,
                    height: 60,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                        ),
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: AppColors.secondary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Floating Action Buttons
          Positioned(
            right: 16,
            bottom: 32,
            child: Column(
              children: [
                FloatingActionButton(
                  heroTag: 'recenter',
                  onPressed: _getCurrentLocation,
                  backgroundColor: AppColors.surface,
                  child: const Icon(Icons.my_location, color: AppColors.secondary),
                ),
                const SizedBox(height: 16),
                FloatingActionButton(
                  heroTag: 'refresh',
                  onPressed: _loadIncidents,
                  backgroundColor: AppColors.surface,
                  child: const Icon(Icons.refresh, color: AppColors.secondary),
                ),
              ],
            ),
          ),

          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  IconData _getIconForType(IncidentType type) {
    switch (type) {
      case IncidentType.theft: return Icons.security;
      case IncidentType.assault: return Icons.warning;
      case IncidentType.harassment: return Icons.block;
      case IncidentType.fire: return Icons.local_fire_department;
      case IncidentType.medical: return Icons.medical_services;
      case IncidentType.other: return Icons.error_outline;
    }
  }

  void _showIncidentDetails(Incident incident) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getSeverityColor(incident.severity).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getIconForType(incident.type),
                    color: _getSeverityColor(incident.severity),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        incident.title,
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        incident.reportedAt,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.foregroundLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              incident.description,
              style: GoogleFonts.inter(
                color: Colors.white,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: AppColors.primary,
                ),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
