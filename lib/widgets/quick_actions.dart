import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';

class QuickActions extends StatelessWidget {
  final String? selectedIncidentId;
  final VoidCallback? onConfirmArrival;
  final VoidCallback? onCallAmbulance;
  final VoidCallback? onCallPolice;
  final VoidCallback? onRequestBackup;
  final VoidCallback? onResolveIncident;
  final VoidCallback? onShareLocation;

  const QuickActions({
    super.key,
    this.selectedIncidentId,
    this.onConfirmArrival,
    this.onCallAmbulance,
    this.onCallPolice,
    this.onRequestBackup,
    this.onResolveIncident,
    this.onShareLocation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.flash_on,
                  color: AppColors.accent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Quick Actions',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Primary Actions Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.3,
            children: [
              _buildActionButton(
                context,
                'Confirm Arrival',
                Icons.check_circle,
                AppColors.success,
                selectedIncidentId != null ? onConfirmArrival : null,
                selectedIncidentId != null 
                    ? 'Mark yourself as arrived on scene'
                    : 'Select an incident first',
              ),
              _buildActionButton(
                context,
                'Call Ambulance',
                Icons.local_hospital,
                AppColors.critical,
                onCallAmbulance, // Always available - doesn't need incident
                'Request emergency medical services',
              ),
              _buildActionButton(
                context,
                'Call Police',
                Icons.local_police,
                AppColors.warning,
                onCallPolice, // Always available - doesn't need incident
                'Contact law enforcement backup',
              ),
              _buildActionButton(
                context,
                'Request Backup',
                Icons.shield,
                AppColors.accent,
                selectedIncidentId != null ? onRequestBackup : null,
                selectedIncidentId != null
                    ? 'Alert other security officers'
                    : 'Select an incident first',
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          const Divider(color: AppColors.border),
          const SizedBox(height: 16),
          
          // Secondary Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onShareLocation,
                  icon: const Icon(Icons.my_location, size: 18),
                  label: const Text('Share Location'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.secondary,
                    side: const BorderSide(color: AppColors.secondary),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: selectedIncidentId != null ? onResolveIncident : null,
                  icon: const Icon(Icons.done_all, size: 18),
                  label: const Text('Resolve'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    disabledBackgroundColor: AppColors.border,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback? onPressed,
    String tooltip,
  ) {
    final isDisabled = onPressed == null;
    
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Opacity(
            opacity: isDisabled ? 0.5 : 1.0,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: color.withOpacity(isDisabled ? 0.05 : 0.1),
              borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: color.withOpacity(isDisabled ? 0.1 : 0.3),
                  width: 2,
                ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                  Icon(icon, color: isDisabled ? AppColors.foregroundLight : color, size: 32),
                const SizedBox(height: 8),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                      color: isDisabled ? AppColors.foregroundLight : Colors.white,
                    height: 1.2,
                  ),
                ),
              ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

