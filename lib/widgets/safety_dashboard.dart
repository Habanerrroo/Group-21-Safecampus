import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';

class SafetyDashboard extends StatelessWidget {
  final int incidentCount;
  final int alertCount;
  final int checkInCount;
  
  const SafetyDashboard({
    super.key,
    this.incidentCount = 0,
    this.alertCount = 0,
    this.checkInCount = 0,
  });

  int get safetyScore {
    // Calculate safety score based on activity
    int score = 100;
    
    // Deduct points for incidents
    score -= (incidentCount * 5).clamp(0, 30);
    
    // Add points for check-ins (up to 20 points)
    score += (checkInCount * 2).clamp(0, 20);
    
    // Ensure score is between 0 and 100
    return score.clamp(0, 100);
  }
  
  String get safetyMessage {
    if (safetyScore >= 90) return 'Excellent! You\'re staying safe and aware.';
    if (safetyScore >= 75) return 'Good! Keep up the safety practices.';
    if (safetyScore >= 60) return 'Fair. Consider improving your safety habits.';
    return 'Needs attention. Please review safety guidelines.';
  }
  
  Color get safetyColor {
    if (safetyScore >= 90) return AppColors.success;
    if (safetyScore >= 75) return AppColors.secondary;
    if (safetyScore >= 60) return AppColors.warning;
    return AppColors.critical;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Safety Overview',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        
        // Safety Score Card
        _buildSafetyScoreCard(),
        const SizedBox(height: 16),
        
        // Stats Grid
        Row(
          children: [
            Expanded(child: _buildStatCard('Reports\nSubmitted', '$incidentCount', Icons.report, AppColors.secondary)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard('Alerts\nReceived', '$alertCount', Icons.notifications, AppColors.warning)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildStatCard('Check-ins\nToday', '$checkInCount', Icons.check_circle, AppColors.success)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard('Active\nStatus', 'Safe', Icons.shield, AppColors.accent)),
          ],
        ),
        const SizedBox(height: 16),
        
        // Quick Tips
        _buildQuickTips(),
      ],
    );
  }

  Widget _buildSafetyScoreCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            safetyColor.withOpacity(0.2),
            AppColors.secondary.withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: safetyColor, width: 2),
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: safetyColor, width: 4),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$safetyScore',
                    style: GoogleFonts.outfit(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: safetyColor,
                    ),
                  ),
                  Text(
                    'SCORE',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.foregroundLight,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Safety Score',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  safetyMessage,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.foregroundLight,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: safetyColor,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Based on your activity',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.foregroundLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.foregroundLight,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickTips() {
    final tips = [
      {'icon': '🌙', 'text': 'Avoid walking alone after dark'},
      {'icon': '👥', 'text': 'Travel in groups when possible'},
      {'icon': '📱', 'text': 'Keep your phone charged'},
      {'icon': '🚨', 'text': 'Know emergency contact numbers'},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb, color: AppColors.warning, size: 20),
              const SizedBox(width: 8),
              Text(
                'Safety Tips',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...tips.map((tip) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Text(
                  tip['icon']!,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    tip['text']!,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.foregroundLight,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

