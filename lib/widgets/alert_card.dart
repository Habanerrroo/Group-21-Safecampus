import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';
import '../models/alert.dart';

class AlertCard extends StatefulWidget {
  final Alert alert;
  final VoidCallback? onTap;

  const AlertCard({
    super.key,
    required this.alert,
    this.onTap,
  });

  @override
  State<AlertCard> createState() => _AlertCardState();
}

class _AlertCardState extends State<AlertCard> {
  bool isExpanded = false;

  Color _getTypeColor() {
    switch (widget.alert.type) {
      case AlertType.critical:
        return AppColors.critical;
      case AlertType.warning:
        return AppColors.warning;
      case AlertType.info:
        return AppColors.info;
      case AlertType.allClear:
        return AppColors.allClear;
    }
  }

  String _getTypeIcon() {
    switch (widget.alert.type) {
      case AlertType.critical:
        return '🚨';
      case AlertType.warning:
        return '⚠️';
      case AlertType.info:
        return 'ℹ️';
      case AlertType.allClear:
        return '✓';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getTypeColor();
    final icon = _getTypeIcon();
    // Use muted border color for read alerts
    final borderColor = widget.alert.isRead 
        ? AppColors.border 
        : color;

    return GestureDetector(
      onTap: () {
        setState(() => isExpanded = !isExpanded);
        widget.onTap?.call();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: widget.alert.isRead 
              ? AppColors.surface 
              : color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 2),
          boxShadow: isExpanded
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 0,
                  ),
                ]
              : [],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        icon,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.alert.title,
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            if (!widget.alert.isRead)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.alert.message,
                          maxLines: isExpanded ? null : 2,
                          overflow: isExpanded ? null : TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppColors.foregroundLight,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Text(
                              widget.alert.timestamp,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.foregroundLight,
                              ),
                            ),
                            if (widget.alert.distance != null) ...[
                              const SizedBox(width: 8),
                              Text(
                                '•',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppColors.foregroundLight,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                widget.alert.distance!,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppColors.foregroundLight,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Expand icon
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: AppColors.foregroundLight,
                    ),
                  ),
                ],
              ),
            ),

            // Expanded actions
            if (isExpanded)
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: color, width: 2),
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: AppColors.border),
                        ),
                        child: const Text('Acknowledge'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          foregroundColor: AppColors.primary,
                        ),
                        child: const Text('Get Help'),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

