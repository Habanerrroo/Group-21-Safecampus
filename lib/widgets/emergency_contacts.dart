import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/theme.dart';
import '../services/emergency_contact_service.dart';
import '../services/personal_contact_service.dart';

class EmergencyContact {
  final String name;
  final String role;
  final String phone;
  final IconData icon;
  final Color color;

  EmergencyContact({
    required this.name,
    required this.role,
    required this.phone,
    required this.icon,
    required this.color,
  });
}

class EmergencyContacts extends StatefulWidget {
  const EmergencyContacts({super.key});

  @override
  State<EmergencyContacts> createState() => _EmergencyContactsState();
}

class _EmergencyContactsState extends State<EmergencyContacts> {
  final _contactService = EmergencyContactService();
  final _personalContactService = PersonalContactService();
  final _supabase = Supabase.instance.client;
  List<EmergencyContact> contacts = [];
  List<EmergencyContact> personalContacts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    setState(() => _isLoading = true);
    
    // Load campus emergency contacts
    final dbContacts = await _contactService.getEmergencyContacts();
    
    // Load personal emergency contacts
    final currentUser = _supabase.auth.currentUser;
    if (currentUser != null) {
      final personal = await _personalContactService.getUserContacts(currentUser.id);
      personalContacts = personal.map((contact) {
        return EmergencyContact(
          name: contact.name,
          role: contact.relationship ?? 'Personal Contact',
          phone: contact.phone,
          icon: Icons.person,
      color: AppColors.accent,
        );
      }).toList();
    }
    
    setState(() {
      contacts = dbContacts.map((contact) {
        return EmergencyContact(
          name: contact.name,
          role: contact.description ?? contact.type,
          phone: contact.phone,
          icon: _getIconForType(contact.type),
          color: _getColorForType(contact.type),
        );
      }).toList();
      _isLoading = false;
    });
  }

  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'campus_security':
        return Icons.shield;
      case 'police':
        return Icons.local_police;
      case 'ambulance':
        return Icons.local_hospital;
      case 'fire':
        return Icons.local_fire_department;
      default:
        return Icons.phone;
    }
  }

  Color _getColorForType(String type) {
    switch (type.toLowerCase()) {
      case 'campus_security':
        return AppColors.accent;
      case 'police':
        return AppColors.warning;
      case 'ambulance':
      case 'fire':
        return AppColors.critical;
      default:
        return AppColors.secondary;
    }
  }

  Future<void> _makePhoneCall(BuildContext context, String phone) async {
    // Remove any non-digit characters except + for international numbers
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final phoneUri = Uri.parse('tel:$cleanPhone');
    
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
        content: Text(
                'Cannot make phone call. Please dial $phone manually.',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
              backgroundColor: AppColors.critical,
              ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
              'Error making call: $e',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
            backgroundColor: AppColors.critical,
                ),
              );
      }
    }
  }

  void _copyToClipboard(BuildContext context, String phone) {
    Clipboard.setData(ClipboardData(text: phone));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Phone number copied to clipboard',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.secondary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (contacts.isEmpty && personalContacts.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'No emergency contacts available',
                style: GoogleFonts.inter(
                  color: AppColors.foregroundLight,
                ),
              ),
            ),
          )
        else ...[
          // Personal Emergency Contacts Section
          if (personalContacts.isNotEmpty) ...[
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: AppColors.accent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Personal Emergency Contacts',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...personalContacts.map((contact) => _buildContactCard(context, contact)),
            const SizedBox(height: 24),
          ],
          
          // Campus Emergency Contacts Section
          if (contacts.isNotEmpty) ...[
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.critical.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.phone_in_talk,
                color: AppColors.critical,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
                  'Campus Emergency Contacts',
              style: GoogleFonts.outfit(
                    fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
            const SizedBox(height: 12),
        ...contacts.map((contact) => _buildContactCard(context, contact)),
          ],
        ],
      ],
    );
  }

  Widget _buildContactCard(BuildContext context, EmergencyContact contact) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _makePhoneCall(context, contact.phone),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: contact.color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    contact.icon,
                    color: contact.color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contact.name,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        contact.role,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.foregroundLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        contact.phone,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: contact.color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    IconButton(
                      onPressed: () => _makePhoneCall(context, contact.phone),
                      icon: const Icon(
                        Icons.phone,
                        color: AppColors.success,
                      ),
                      tooltip: 'Call',
                    ),
                    IconButton(
                      onPressed: () => _copyToClipboard(context, contact.phone),
                      icon: const Icon(
                        Icons.copy,
                        color: AppColors.secondary,
                        size: 20,
                      ),
                      tooltip: 'Copy number',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

