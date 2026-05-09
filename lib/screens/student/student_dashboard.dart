import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../models/alert.dart';
import '../../widgets/student_header.dart';
import '../../widgets/emergency_button.dart';
import '../../widgets/alert_card.dart';
import 'incident_composer_screen.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  int _selectedTab = 0;
  bool _submitted = false;

  final List<Alert> mockAlerts = [
    Alert(
      id: 'alert-1',
      title: 'Critical Incident Nearby',
      message: 'Assault reported near the library entrance. Security officers are responding. Avoid the area.',
      type: AlertType.critical,
      timestamp: '5 minutes ago',
      distance: '0.3 km away',
      isRead: false,
    ),
    Alert(
      id: 'alert-2',
      title: 'Campus Safety Tip',
      message: 'Travel in groups after dark. Campus patrol is active throughout the evening.',
      type: AlertType.info,
      timestamp: '1 hour ago',
      isRead: true,
    ),
    Alert(
      id: 'alert-3',
      title: 'All Clear Notice',
      message: 'The area around North Campus Parking has been cleared. It is now safe to access.',
      type: AlertType.allClear,
      timestamp: '2 hours ago',
      isRead: true,
    ),
    Alert(
      id: 'alert-4',
      title: 'Security Warning',
      message: 'Suspicious activity reported in the Student Center. Increased patrol in effect.',
      type: AlertType.warning,
      timestamp: '3 hours ago',
      distance: '0.5 km away',
      isRead: true,
    ),
  ];

  void _handleReportSubmit() {
    setState(() => _submitted = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _submitted = false;
          _selectedTab = 0;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            StudentHeader(
              userName: 'Sarah',
              unreadCount: 1,
              onNotifications: () {},
              onProfile: () {},
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Emergency Section
                    _buildEmergencySection(),

                    // Tab Navigation
                    _buildTabNavigation(),

                    // Tab Content
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: _selectedTab == 0
                          ? _buildAlertsTab()
                          : _buildReportTab(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencySection() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.accent.withOpacity(0.2),
            const Color(0xFFFF6B00).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accent, width: 2),
      ),
      child: Column(
        children: [
          Text(
            'Need Immediate Help?',
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Press and hold the button below for 3 seconds to send an emergency alert',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.foregroundLight,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          EmergencyButton(
            onActivate: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Emergency SOS sent to campus security!',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                  backgroundColor: AppColors.accent,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTabNavigation() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      child: Row(
        children: [
          _buildTab('Safety Alerts', 0),
          _buildTab('Report Incident', 1),
        ],
      ),
    );
  }

  Widget _buildTab(String title, int index) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? AppColors.secondary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isSelected ? AppColors.secondary : AppColors.foregroundLight,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAlertsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Safety Alerts',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        ...mockAlerts.map((alert) => AlertCard(alert: alert)),
      ],
    );
  }

  Widget _buildReportTab() {
    if (_submitted) {
      return Container(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                color: Colors.white,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Report Submitted',
              style: GoogleFonts.outfit(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Thank you for helping keep our campus safe. Security officers have been notified.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.foregroundLight,
                height: 1.5,
              ),
            ),
          ],
        ),
      );
    }

    return IncidentComposerScreen(
      onSubmit: _handleReportSubmit,
    );
  }
}

