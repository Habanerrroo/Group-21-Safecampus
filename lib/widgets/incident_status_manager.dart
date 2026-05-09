import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';

enum IncidentStatusType {
  reported,
  dispatched,
  enRoute,
  arrived,
  inProgress,
  resolved,
  cancelled,
}

class IncidentStatusManager extends StatefulWidget {
  final String incidentId;
  final IncidentStatusType currentStatus;
  final Function(IncidentStatusType) onStatusChange;

  const IncidentStatusManager({
    super.key,
    required this.incidentId,
    required this.currentStatus,
    required this.onStatusChange,
  });

  @override
  State<IncidentStatusManager> createState() => _IncidentStatusManagerState();
}

class _IncidentStatusManagerState extends State<IncidentStatusManager> {
  late IncidentStatusType _selectedStatus;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.currentStatus;
  }

  Color _getStatusColor(IncidentStatusType status) {
    switch (status) {
      case IncidentStatusType.reported:
        return AppColors.warning;
      case IncidentStatusType.dispatched:
        return AppColors.accent;
      case IncidentStatusType.enRoute:
        return AppColors.secondary;
      case IncidentStatusType.arrived:
        return AppColors.info;
      case IncidentStatusType.inProgress:
        return AppColors.accent;
      case IncidentStatusType.resolved:
        return AppColors.success;
      case IncidentStatusType.cancelled:
        return AppColors.foregroundLight;
    }
  }

  IconData _getStatusIcon(IncidentStatusType status) {
    switch (status) {
      case IncidentStatusType.reported:
        return Icons.report;
      case IncidentStatusType.dispatched:
        return Icons.send;
      case IncidentStatusType.enRoute:
        return Icons.directions_car;
      case IncidentStatusType.arrived:
        return Icons.place;
      case IncidentStatusType.inProgress:
        return Icons.settings;
      case IncidentStatusType.resolved:
        return Icons.check_circle;
      case IncidentStatusType.cancelled:
        return Icons.cancel;
    }
  }

  String _getStatusLabel(IncidentStatusType status) {
    return status.name.replaceAllMapped(
      RegExp(r'([A-Z])'),
      (match) => ' ${match.group(0)}',
    ).trim();
  }

  void _updateStatus(IncidentStatusType newStatus) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Update Status',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Change incident status to:',
              style: GoogleFonts.inter(
                color: AppColors.foregroundLight,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getStatusColor(newStatus).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getStatusColor(newStatus),
                  width: 2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getStatusIcon(newStatus),
                    color: _getStatusColor(newStatus),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _getStatusLabel(newStatus).toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(newStatus),
                    ),
                  ),
                ],
              ),
            ),
            if (newStatus == IncidentStatusType.resolved) ...[
              const SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Add resolution notes (optional)',
                  hintStyle: GoogleFonts.inter(
                    color: AppColors.foregroundLight,
                  ),
                ),
                maxLines: 3,
                style: GoogleFonts.inter(color: Colors.white),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: AppColors.foregroundLight),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _selectedStatus = newStatus);
              widget.onStatusChange(newStatus);
              Navigator.pop(context);
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Status updated to ${_getStatusLabel(newStatus)}',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                  backgroundColor: _getStatusColor(newStatus),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _getStatusColor(newStatus),
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

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
                  color: _getStatusColor(_selectedStatus).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getStatusIcon(_selectedStatus),
                  color: _getStatusColor(_selectedStatus),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Status',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.foregroundLight,
                      ),
                    ),
                    Text(
                      _getStatusLabel(_selectedStatus).toUpperCase(),
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(_selectedStatus),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: AppColors.border),
          const SizedBox(height: 12),
          Text(
            'Update Status',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          
          // Status options
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: IncidentStatusType.values.map((status) {
              final isSelected = status == _selectedStatus;
              final color = _getStatusColor(status);
              
              return GestureDetector(
                onTap: () => _updateStatus(status),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? color : AppColors.border,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getStatusIcon(status),
                        size: 16,
                        color: isSelected ? color : AppColors.foregroundLight,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _getStatusLabel(status),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected ? color : AppColors.foregroundLight,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

