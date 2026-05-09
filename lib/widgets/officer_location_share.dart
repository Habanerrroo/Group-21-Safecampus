import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import '../config/theme.dart';

class OfficerLocationShare extends StatefulWidget {
  final String officerId;
  final Function(Position)? onLocationShared;

  const OfficerLocationShare({
    super.key,
    required this.officerId,
    this.onLocationShared,
  });

  @override
  State<OfficerLocationShare> createState() => _OfficerLocationShareState();
}

class _OfficerLocationShareState extends State<OfficerLocationShare> {
  bool _isSharingLocation = false;
  Position? _currentPosition;
  DateTime? _lastUpdate;

  Future<void> _toggleLocationSharing() async {
    if (_isSharingLocation) {
      setState(() {
        _isSharingLocation = false;
      });
      return;
    }

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showError('Location services are disabled');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showError('Location permissions denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showError('Location permissions permanently denied');
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = position;
        _lastUpdate = DateTime.now();
        _isSharingLocation = true;
      });

      widget.onLocationShared?.call(position);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Location sharing enabled',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      _showError('Error getting location: $e');
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppColors.critical,
        ),
      );
    }
  }

  String _getTimeAgo() {
    if (_lastUpdate == null) return 'Never';
    
    final diff = DateTime.now().difference(_lastUpdate!);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isSharingLocation ? AppColors.success : AppColors.border,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (_isSharingLocation ? AppColors.success : AppColors.foregroundLight)
                      .withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _isSharingLocation ? Icons.location_on : Icons.location_off,
                  color: _isSharingLocation ? AppColors.success : AppColors.foregroundLight,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Location Sharing',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      _isSharingLocation ? 'Active' : 'Inactive',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: _isSharingLocation ? AppColors.success : AppColors.foregroundLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _isSharingLocation,
                onChanged: (value) => _toggleLocationSharing(),
                activeColor: AppColors.success,
              ),
            ],
          ),
          
          if (_currentPosition != null && _isSharingLocation) ...[
            const SizedBox(height: 16),
            const Divider(color: AppColors.border),
            const SizedBox(height: 16),
            
            // Location details
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryLighter,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildInfoRow(
                    'Latitude',
                    _currentPosition!.latitude.toStringAsFixed(6),
                    Icons.south,
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    'Longitude',
                    _currentPosition!.longitude.toStringAsFixed(6),
                    Icons.east,
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    'Accuracy',
                    '${_currentPosition!.accuracy.toStringAsFixed(1)}m',
                    Icons.my_location,
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    'Last Updated',
                    _getTimeAgo(),
                    Icons.access_time,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _toggleLocationSharing,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Refresh'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.secondary,
                      side: const BorderSide(color: AppColors.secondary),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // In production, this would broadcast to team
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Location shared with team',
                            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                          ),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    },
                    icon: const Icon(Icons.share_location, size: 18),
                    label: const Text('Share'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
          
          if (!_isSharingLocation) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.warning.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.warning,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Enable location sharing to help dispatch track your position',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.foregroundLight,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.secondary),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppColors.foregroundLight,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.robotoMono(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

