import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/theme.dart';
import '../../models/incident.dart';
import '../../services/map_service.dart';

/// A real-time map view for security officers to navigate to active incidents.
/// Displays officer position (blue) and incident position (red).
class IncidentMapScreen extends StatefulWidget {
  final Incident incident;
  final List<Incident>? allIncidents; // Optional: show all incidents on map

  const IncidentMapScreen({
    super.key,
    required this.incident,
    this.allIncidents,
  });

  @override
  State<IncidentMapScreen> createState() => _IncidentMapScreenState();
}

class _IncidentMapScreenState extends State<IncidentMapScreen> {
  final MapController _mapController = MapController();
  final MapService _mapService = MapService();
  LatLng? _currentLocation;
  List<LatLng>? _routePoints;
  bool _isLoadingRoute = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation().then((_) {
      _fetchRoute();
    });
    // Center map on incident location after a short delay
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerOnIncident();
    });
  }

  Future<void> _fetchRoute() async {
    final incidentLocation = _mapService.incidentToLatLng(widget.incident);
    if (_currentLocation != null && incidentLocation != null) {
      setState(() => _isLoadingRoute = true);
      try {
        final points = await _mapService.calculateRoute(_currentLocation!, incidentLocation);
        setState(() => _routePoints = points);
      } finally {
        if (mounted) {
          setState(() => _isLoadingRoute = false);
        }
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (mounted) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
        });
      }
    } catch (e) {
    }
  }

  void _centerOnIncident() {
    final incidentLocation = _mapService.incidentToLatLng(widget.incident);
    if (incidentLocation != null) {
      _mapController.move(incidentLocation, 17.0);
    }
  }

  void _centerOnCurrentLocation() {
    if (_currentLocation != null) {
      _mapController.move(_currentLocation!, 17.0);
    } else {
      _getCurrentLocation().then((_) => _fetchRoute());
    }
  }

  Color _getIncidentMarkerColor(Incident incident) {
    switch (incident.severity) {
      case IncidentSeverity.critical:
        return Colors.red;
      case IncidentSeverity.high:
        return Colors.orange;
      case IncidentSeverity.medium:
        return Colors.yellow;
      case IncidentSeverity.low:
        return Colors.green;
    }
  }

  String _getIncidentIcon(IncidentType type) {
    switch (type) {
      case IncidentType.theft:
        return '👜';
      case IncidentType.assault:
        return '👊';
      case IncidentType.harassment:
        return '⚠️';
      case IncidentType.fire:
        return '🔥';
      case IncidentType.medical:
        return '🏥';
      case IncidentType.other:
        return '📍';
    }
  }

  @override
  Widget build(BuildContext context) {
    final incidentLocation = _mapService.incidentToLatLng(widget.incident);
    final defaultCenter = _mapService.getDefaultCenter();
    final center = incidentLocation ?? defaultCenter;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Navigate to Incident',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (_currentLocation != null)
            IconButton(
              icon: const Icon(Icons.my_location, color: AppColors.secondary),
              onPressed: _centerOnCurrentLocation,
              tooltip: 'Center on my location',
            ),
        ],
      ),
      body: Stack(
        children: [
          // Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: center,
              initialZoom: 16.0,
              minZoom: 10.0,
              maxZoom: 18.0,
              onTap: (tapPosition, point) {
                // Handle map tap if needed
              },
            ),
            children: [
              // OpenStreetMap tiles
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.safecampus.app',
                maxZoom: 19,
              ),
              // Route polyline (if available)
              if (_routePoints != null && _routePoints!.length > 1)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints!,
                      strokeWidth: 4.0,
                      color: AppColors.secondary,
                    ),
                  ],
                ),
              // Markers
              MarkerLayer(
                markers: [
                  // Current user location (blue)
                  if (_currentLocation != null)
                    Marker(
                      point: _currentLocation!,
                      width: 40,
                      height: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.blue, width: 3),
                        ),
                        child: const Icon(
                          Icons.person_pin_circle,
                          color: Colors.blue,
                          size: 24,
                        ),
                      ),
                    ),
                  // Main incident marker (red/orange based on severity)
                  if (incidentLocation != null)
                    Marker(
                      point: incidentLocation,
                      width: 50,
                      height: 50,
                      child: Container(
                        decoration: BoxDecoration(
                          color: _getIncidentMarkerColor(widget.incident).withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _getIncidentMarkerColor(widget.incident),
                            width: 3,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            _getIncidentIcon(widget.incident.type),
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                      ),
                    ),
                  // Other incidents (if showing all)
                  if (widget.allIncidents != null)
                    ...widget.allIncidents!
                        .where((inc) => inc.id != widget.incident.id)
                        .map((inc) {
                      final loc = _mapService.incidentToLatLng(inc);
                      if (loc == null) return null;
                      return Marker(
                        point: loc,
                        width: 35,
                        height: 35,
                        child: Container(
                          decoration: BoxDecoration(
                            color: _getIncidentMarkerColor(inc).withOpacity(0.2),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _getIncidentMarkerColor(inc),
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              _getIncidentIcon(inc.type),
                              style: const TextStyle(fontSize: 18),
                            ),
                          ),
                        ),
                      );
                    }).whereType<Marker>(),
                ],
              ),
            ],
          ),
          // Loading indicator for route
          if (_isLoadingRoute)
            Positioned(
              top: 16,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.secondary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Calculating route...',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: center,
              initialZoom: 16.0,
              minZoom: 10.0,
              maxZoom: 18.0,
              onTap: (tapPosition, point) {
                // Handle map tap if needed
              },
            ),
            children: [
              // OpenStreetMap tiles
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.safecampus.app',
                maxZoom: 19,
              ),
              // Route polyline (if available)
              if (_routePoints != null && _routePoints!.length > 1)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints!,
                      strokeWidth: 4.0,
                      color: AppColors.secondary,
                    ),
                  ],
                ),
              // Markers
              MarkerLayer(
                markers: [
                  // Current user location (blue)
                  if (_currentLocation != null)
                    Marker(
                      point: _currentLocation!,
                      width: 40,
                      height: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.blue, width: 3),
                        ),
                        child: const Icon(
                          Icons.person_pin_circle,
                          color: Colors.blue,
                          size: 24,
                        ),
                      ),
                    ),
                  // Main incident marker (red/orange based on severity)
                  if (incidentLocation != null)
                    Marker(
                      point: incidentLocation,
                      width: 50,
                      height: 50,
                      child: Container(
                        decoration: BoxDecoration(
                          color: _getIncidentMarkerColor(widget.incident).withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _getIncidentMarkerColor(widget.incident),
                            width: 3,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            _getIncidentIcon(widget.incident.type),
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                      ),
                    ),
                  // Other incidents (if showing all)
                  if (widget.allIncidents != null)
                    ...widget.allIncidents!
                        .where((inc) => inc.id != widget.incident.id)
                        .map((inc) {
                      final loc = _mapService.incidentToLatLng(inc);
                      if (loc == null) return null;
                      return Marker(
                        point: loc,
                        width: 35,
                        height: 35,
                        child: Container(
                          decoration: BoxDecoration(
                            color: _getIncidentMarkerColor(inc).withOpacity(0.2),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _getIncidentMarkerColor(inc),
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              _getIncidentIcon(inc.type),
                              style: const TextStyle(fontSize: 18),
                            ),
                          ),
                        ),
                      );
                    }).whereType<Marker>(),
                ],
              ),
            ],
          ),
          // Incident info card at bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag handle
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _getIncidentMarkerColor(widget.incident),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                widget.incident.severity.name.toUpperCase(),
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                widget.incident.title,
                                style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 16,
                              color: AppColors.secondary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.incident.location,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: AppColors.foregroundLight,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_currentLocation != null && incidentLocation != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.navigation,
                                size: 16,
                                color: AppColors.secondary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _mapService.getDistanceString(
                                  _currentLocation!,
                                  incidentLocation,
                                ),
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.secondary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '• ${_mapService.getBearingString(_currentLocation!, incidentLocation)}',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: AppColors.foregroundLight,
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              // Open in external maps app
                              _openInExternalMaps(incidentLocation);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.secondary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Open in Maps App',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openInExternalMaps(LatLng? location) async {
    if (location == null) return;

    final lat = location.latitude;
    final lng = location.longitude;

    // Try Google Maps first, fallback to Apple Maps
    final googleMapsUrl = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
    final appleMapsUrl = Uri.parse('https://maps.apple.com/?daddr=$lat,$lng');

    try {
      // Try Google Maps first
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(appleMapsUrl)) {
        // Fallback to Apple Maps
        await launchUrl(appleMapsUrl, mode: LaunchMode.externalApplication);
      } else {
        // Last resort: generic maps URL
        final genericUrl = Uri.parse('geo:$lat,$lng?q=$lat,$lng');
        if (await canLaunchUrl(genericUrl)) {
          await launchUrl(genericUrl, mode: LaunchMode.externalApplication);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Could not open maps app')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error opening maps app')),
        );
      }
    }
  }
}

