import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';

class BuddyCheckIn extends StatefulWidget {
  const BuddyCheckIn({super.key});

  @override
  State<BuddyCheckIn> createState() => _BuddyCheckInState();
}

class _BuddyCheckInState extends State<BuddyCheckIn> {
  final List<Buddy> _buddies = [
    Buddy(
      name: 'John Doe',
      status: BuddyStatus.safe,
      lastCheckIn: '5 min ago',
      location: 'Library',
    ),
    Buddy(
      name: 'Jane Smith',
      status: BuddyStatus.safe,
      lastCheckIn: '15 min ago',
      location: 'Student Center',
    ),
    Buddy(
      name: 'Mike Johnson',
      status: BuddyStatus.needsHelp,
      lastCheckIn: '2 hours ago',
      location: 'Unknown',
    ),
  ];

  void _checkIn() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Check In',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Let your buddies know you\'re safe',
              style: GoogleFonts.inter(
                color: AppColors.foregroundLight,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildCheckInOption(
                  context,
                  'I\'m Safe',
                  Icons.check_circle,
                  AppColors.success,
                ),
                _buildCheckInOption(
                  context,
                  'Need Help',
                  Icons.warning,
                  AppColors.critical,
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                color: AppColors.foregroundLight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckInOption(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Check-in sent: $label',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            backgroundColor: color,
          ),
        );
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.people,
                    color: AppColors.secondary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Buddy System',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            ElevatedButton.icon(
              onPressed: _checkIn,
              icon: const Icon(Icons.check_circle, size: 18),
              label: const Text('Check In'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Buddies List
        ..._buddies.map((buddy) => _buildBuddyCard(buddy)),
        
        const SizedBox(height: 12),
        
        // Add Buddy Button
        OutlinedButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Add buddy feature coming soon!',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
                backgroundColor: AppColors.secondary,
              ),
            );
          },
          icon: const Icon(Icons.person_add),
          label: const Text('Add Buddy'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.secondary,
            side: const BorderSide(color: AppColors.secondary),
          ),
        ),
      ],
    );
  }

  Widget _buildBuddyCard(Buddy buddy) {
    Color statusColor;
    IconData statusIcon;
    
    switch (buddy.status) {
      case BuddyStatus.safe:
        statusColor = AppColors.success;
        statusIcon = Icons.check_circle;
        break;
      case BuddyStatus.needsHelp:
        statusColor = AppColors.critical;
        statusIcon = Icons.warning;
        break;
      case BuddyStatus.offline:
        statusColor = AppColors.foregroundLight;
        statusIcon = Icons.circle;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: buddy.status == BuddyStatus.needsHelp
              ? AppColors.critical
              : AppColors.border,
          width: buddy.status == BuddyStatus.needsHelp ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppColors.secondary,
                      AppColors.secondaryLight,
                    ],
                  ),
                ),
                child: Center(
                  child: Text(
                    buddy.name[0],
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.surface, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  buddy.name,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(statusIcon, size: 14, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      buddy.status.name.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '•',
                      style: TextStyle(color: AppColors.foregroundLight),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      buddy.lastCheckIn,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.foregroundLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 12,
                      color: AppColors.foregroundLight,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      buddy.location,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.foregroundLight,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (buddy.status == BuddyStatus.needsHelp)
            IconButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Alerting security about ${buddy.name}',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                    ),
                    backgroundColor: AppColors.critical,
                  ),
                );
              },
              icon: const Icon(
                Icons.phone,
                color: AppColors.critical,
              ),
            ),
        ],
      ),
    );
  }
}

class Buddy {
  final String name;
  final BuddyStatus status;
  final String lastCheckIn;
  final String location;

  Buddy({
    required this.name,
    required this.status,
    required this.lastCheckIn,
    required this.location,
  });
}

enum BuddyStatus {
  safe,
  needsHelp,
  offline,
}

