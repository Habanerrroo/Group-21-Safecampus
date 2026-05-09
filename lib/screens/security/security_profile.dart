import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/theme.dart';
import '../../models/user.dart' as models;
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../services/incident_service.dart';
import '../../services/storage_service_upload.dart';
import '../auth/login_screen.dart';

class SecurityProfile extends StatefulWidget {
  const SecurityProfile({super.key});

  @override
  State<SecurityProfile> createState() => _SecurityProfileState();
}

class _SecurityProfileState extends State<SecurityProfile> {
  final _authService = AuthService();
  final _userService = UserService();
  final _incidentService = IncidentService();
  final _storageService = StorageServiceUpload();
  final _imagePicker = ImagePicker();

  models.User? _currentUser;
  int _assignedIncidents = 0;
  int _resolvedIncidents = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    try {
      _currentUser = await _authService.getCurrentUser();

      if (_currentUser != null) {
        // Get incidents assigned to this officer
        final incidents = await _incidentService.getOfficerIncidents(_currentUser!.id);
        _assignedIncidents = incidents.length;

        // Get resolved incidents assigned to this officer
        final supabase = Supabase.instance.client;
        final resolvedResponse = await supabase
            .from('incidents')
            .select()
            .eq('assigned_officer', _currentUser!.id)
            .eq('status', 'resolved');
        _resolvedIncidents = (resolvedResponse as List).length;
      }
    } catch (e) {
      print('[SecurityProfile] Error loading data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.secondary))
            : SingleChildScrollView(
                child: Column(
                  children: [
                    _buildProfileHeader(),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildPerformanceStats(),
                          const SizedBox(height: 24),
                          _buildPersonalInfo(),
                          const SizedBox(height: 24),
                          _buildNotificationSettings(),
                          const SizedBox(height: 24),
                          _buildDangerZone(),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.accent,
            AppColors.accentLight,
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Stack(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: _currentUser?.profileImage != null && _currentUser!.profileImage!.isNotEmpty
                        ? ClipOval(
                            child: Image.network(
                              _currentUser!.profileImage!,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Text(
                                    _currentUser?.name.isNotEmpty == true
                                        ? _currentUser!.name[0].toUpperCase()
                                        : 'O',
                                    style: GoogleFonts.outfit(
                                      fontSize: 48,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.accent,
                                    ),
                                  ),
                                );
                              },
                            ),
                          )
                        : Center(
                            child: Text(
                              _currentUser?.name.isNotEmpty == true
                                  ? _currentUser!.name[0].toUpperCase()
                                  : 'O',
                              style: GoogleFonts.outfit(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: AppColors.accent,
                              ),
                            ),
                          ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _handlePhotoUpload,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.secondary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                _currentUser?.name ?? 'Officer',
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'SECURITY OFFICER',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              const SizedBox(height: 4),
              if (_currentUser?.studentId != null)
                Text(
                  'Badge #${_currentUser!.studentId}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _showEditProfileDialog,
                icon: const Icon(Icons.edit, size: 18),
                label: const Text('Edit Profile'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white, width: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPerformanceStats() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Performance',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Active Cases',
                  '$_assignedIncidents',
                  Icons.assignment,
                  AppColors.warning,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Resolved',
                  '$_resolvedIncidents',
                  Icons.check_circle,
                  AppColors.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.foregroundLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfo() {
    return _buildSection(
      'Personal Information',
      Icons.person,
      [
        _buildInfoRow('Email', _currentUser?.email ?? 'Not set', Icons.email),
        _buildInfoRow('Phone', _currentUser?.phone ?? 'Not set', Icons.phone),
        _buildInfoRow('Badge Number', _currentUser?.studentId ?? 'Not set', Icons.badge),
      ],
    );
  }

  Widget _buildNotificationSettings() {
    return _buildSection(
      'Notification Settings',
      Icons.notifications,
      [
        SwitchListTile(
          title: Text(
            'Emergency Alerts',
            style: GoogleFonts.inter(fontSize: 14, color: Colors.white),
          ),
          subtitle: Text(
            'Get notified of critical incidents',
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.foregroundLight),
          ),
          value: true,
          onChanged: (value) {},
          activeColor: AppColors.secondary,
        ),
        SwitchListTile(
          title: Text(
            'Incident Assignments',
            style: GoogleFonts.inter(fontSize: 14, color: Colors.white),
          ),
          subtitle: Text(
            'Notifications when assigned to incidents',
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.foregroundLight),
          ),
          value: true,
          onChanged: (value) {},
          activeColor: AppColors.secondary,
        ),
      ],
    );
  }

  Widget _buildDangerZone() {
    return _buildSection(
      'Account',
      Icons.settings,
      [
        ListTile(
          leading: const Icon(Icons.logout, color: AppColors.critical),
          title: Text(
            'Logout',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.critical,
            ),
          ),
          onTap: _handleLogout,
        ),
      ],
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(icon, color: AppColors.secondary, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.foregroundLight, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.foregroundLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditProfileDialog() async {
    final nameController = TextEditingController(text: _currentUser?.name);
    final badgeController = TextEditingController(text: _currentUser?.studentId);
    final phoneController = TextEditingController(text: _currentUser?.phone);

    String? newName;
    String? newBadge;
    String? newPhone;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Edit Profile',
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: GoogleFonts.inter(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Name',
                  labelStyle: GoogleFonts.inter(color: AppColors.foregroundLight),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: badgeController,
                style: GoogleFonts.inter(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Badge Number',
                  labelStyle: GoogleFonts.inter(color: AppColors.foregroundLight),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                style: GoogleFonts.inter(color: Colors.white),
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone',
                  labelStyle: GoogleFonts.inter(color: AppColors.foregroundLight),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.inter(color: AppColors.foregroundLight)),
          ),
          ElevatedButton(
            onPressed: () {
              newName = nameController.text;
              newBadge = badgeController.text;
              newPhone = phoneController.text;
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    nameController.dispose();
    badgeController.dispose();
    phoneController.dispose();

    if (result == true && _currentUser != null && newName != null) {
      final success = await _userService.updateUserProfile(
        userId: _currentUser!.id,
        name: newName!,
        studentId: newBadge,
        phone: newPhone,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Profile updated successfully!',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            backgroundColor: AppColors.success,
          ),
        );
        _loadUserData();
      }
    }
  }

  Future<void> _handlePhotoUpload() async {
    if (_currentUser == null) return;

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image == null) return;

      // Show loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 16),
                Text(
                  'Uploading photo...',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            backgroundColor: AppColors.secondary,
            duration: const Duration(seconds: 30),
          ),
        );
      }

      // Upload to storage
      final imageUrl = await _storageService.uploadProfilePhoto(
        userId: _currentUser!.id,
        filePath: image.path,
      );

      if (imageUrl == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to upload photo. Please try again.',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
              backgroundColor: AppColors.critical,
            ),
          );
        }
        return;
      }

      // Update user profile
      final success = await _userService.updateUserProfile(
        userId: _currentUser!.id,
        profileImage: imageUrl,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Profile photo updated!',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            backgroundColor: AppColors.success,
          ),
        );
        _loadUserData(); // Reload to show new photo
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to update profile. Please try again.',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
              backgroundColor: AppColors.critical,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: $e',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            backgroundColor: AppColors.critical,
          ),
        );
      }
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Logout',
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: GoogleFonts.inter(color: AppColors.foregroundLight),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.inter(color: AppColors.foregroundLight)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.critical),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _authService.logout();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }
}

