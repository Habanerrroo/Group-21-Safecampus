import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/theme.dart';
import '../../widgets/location_picker.dart';
import '../../models/user.dart' as models;
import '../../services/user_service.dart';
import '../../services/incident_service.dart';
import '../../services/auth_service.dart';
import '../../services/personal_contact_service.dart';
import '../auth/login_screen.dart';

class StudentProfile extends StatefulWidget {
  final models.User? user;
  
  const StudentProfile({super.key, this.user});

  @override
  State<StudentProfile> createState() => _StudentProfileState();
}

class _StudentProfileState extends State<StudentProfile> {
  bool _notificationsEnabled = true;
  bool _locationSharingEnabled = true;
  bool _buddyAlertsEnabled = true;
  String _safetyRadius = '1.0'; // km
  
  final _userService = UserService();
  final _incidentService = IncidentService();
  final _authService = AuthService();
  final _personalContactService = PersonalContactService();
  final _imagePicker = ImagePicker();
  
  models.User? _currentUser;
  int _incidentCount = 0;
  bool _isLoading = true;
  bool _isUploadingPhoto = false;
  List<PersonalContact> _personalContacts = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }
  
  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    
    // Use passed user or fetch current user
    _currentUser = widget.user ?? await _userService.getCurrentUser();
    
    // Load user's incident count and personal contacts
    if (_currentUser != null) {
      final incidents = await _incidentService.getUserIncidents(_currentUser!.id);
      _incidentCount = incidents.length;
      
      // Load personal contacts
      _personalContacts = await _personalContactService.getUserContacts(_currentUser!.id);
    }
    
    setState(() => _isLoading = false);
  }
  
  Future<void> _showEditProfileDialog() async {
    final nameController = TextEditingController(text: _currentUser?.name);
    final studentIdController = TextEditingController(text: _currentUser?.studentId);
    final phoneController = TextEditingController(text: _currentUser?.phone);
    final residenceController = TextEditingController(text: _currentUser?.residence);
    
    // Store values before dialog closes
    String? newName;
    String? newStudentId;
    String? newPhone;
    String? newResidence;
    
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
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.secondary, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: studentIdController,
                style: GoogleFonts.inter(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Student ID',
                  labelStyle: GoogleFonts.inter(color: AppColors.foregroundLight),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.secondary, width: 2),
                  ),
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
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.secondary, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              LocationPicker(
                selectedLocation: _currentUser?.residence ?? (residenceController.text.isNotEmpty ? residenceController.text : null),
                onLocationSelected: (location) {
                  residenceController.text = location;
                },
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
              newStudentId = studentIdController.text;
              newPhone = phoneController.text;
              newResidence = residenceController.text;
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    
    // Dispose controllers immediately after dialog closes
    nameController.dispose();
    studentIdController.dispose();
    phoneController.dispose();
    residenceController.dispose();
    
    // Use stored values for update
    if (result == true && _currentUser != null && newName != null) {
      final success = await _userService.updateUserProfile(
        userId: _currentUser!.id,
        name: newName!,
        studentId: newStudentId,
        phone: newPhone,
        residence: newResidence,
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
        _loadUserData(); // Reload data
      }
    }
  }

  Future<void> _showAddContactDialog() async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final relationshipController = TextEditingController();
    
    // Store values before dialog closes
    String? contactName;
    String? contactPhone;
    String? contactRelationship;
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Add Emergency Contact',
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
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.secondary, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                style: GoogleFonts.inter(color: Colors.white),
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  labelStyle: GoogleFonts.inter(color: AppColors.foregroundLight),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.secondary, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: relationshipController,
                style: GoogleFonts.inter(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Relationship (e.g., Father, Mother)',
                  labelStyle: GoogleFonts.inter(color: AppColors.foregroundLight),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.secondary, width: 2),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Dispose controllers before closing dialog
              nameController.dispose();
              phoneController.dispose();
              relationshipController.dispose();
              
              Navigator.pop(context, false);
            },
            child: Text('Cancel', style: GoogleFonts.inter(color: AppColors.foregroundLight)),
          ),
          ElevatedButton(
            onPressed: () {
              // Capture values before disposing
              contactName = nameController.text;
              contactPhone = phoneController.text;
              contactRelationship = relationshipController.text;
              
              // Dispose controllers before closing dialog
              nameController.dispose();
              phoneController.dispose();
              relationshipController.dispose();
              
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    
    // Validate and show message
    if (result == true && contactName != null && contactPhone != null) {
      if (contactName!.isEmpty || contactPhone!.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Please fill in all required fields',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
              backgroundColor: AppColors.critical,
            ),
          );
        }
        return;
      }
      
      // Save to database
      if (_currentUser != null) {
        final contactId = await _personalContactService.addContact(
          userId: _currentUser!.id,
          name: contactName!,
          phone: contactPhone!,
          relationship: contactRelationship?.isNotEmpty == true ? contactRelationship : null,
        );
        
        if (mounted) {
          if (contactId != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Contact added successfully!',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
                backgroundColor: AppColors.success,
              ),
            );
            // Reload contacts
            await _loadUserData();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Failed to add contact. Please try again.',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
                backgroundColor: AppColors.critical,
              ),
            );
          }
        }
      }
    }
  }

  Future<void> _handlePhotoUpload() async {
    if (_currentUser == null) return;

    // Show options: Camera or Gallery
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Select Photo Source',
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.accent),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.accent),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (pickedFile == null) return;

      setState(() => _isUploadingPhoto = true);

      // Upload photo
      final photoUrl = await _userService.uploadProfilePhoto(
        userId: _currentUser!.id,
        filePath: pickedFile.path,
      );

      if (mounted) {
        if (photoUrl != null) {
          // Reload user data to get updated profile image
          await _loadUserData();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Profile photo updated successfully!',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
              backgroundColor: AppColors.success,
            ),
          );
        } else {
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
        setState(() => _isUploadingPhoto = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: ${e.toString()}',
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Profile',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Settings saved!',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            icon: const Icon(Icons.save),
            tooltip: 'Save Settings',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildProfileHeader(),
            const SizedBox(height: 24),
            _buildSafetyScore(),
            const SizedBox(height: 24),
            _buildPersonalInfo(),
            const SizedBox(height: 24),
            _buildEmergencyContacts(),
            const SizedBox(height: 24),
            _buildNotificationSettings(),
            const SizedBox(height: 24),
            _buildActivityHistory(),
            const SizedBox(height: 24),
            _buildDangerZone(),
            const SizedBox(height: 40),
          ],
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
            AppColors.secondary,
            AppColors.secondaryLight,
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
                    child: Center(
                      child: _currentUser?.profileImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(50),
                              child: Image.network(
                                _currentUser!.profileImage!,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Text(
                                    _currentUser?.name.substring(0, 1).toUpperCase() ?? 'S',
                                    style: GoogleFonts.outfit(
                                      fontSize: 48,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.secondary,
                                    ),
                                  );
                                },
                              ),
                            )
                          : Text(
                              _currentUser?.name.substring(0, 1).toUpperCase() ?? 'S',
                              style: GoogleFonts.outfit(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: AppColors.secondary,
                              ),
                            ),
                    ),
                  ),
                  if (_currentUser?.profileImage != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(50),
                      child: Image.network(
                        _currentUser!.profileImage!,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                    ),
                    child: Center(
                      child: Text(
                                _currentUser?.name.substring(0, 1).toUpperCase() ?? 'S',
                        style: GoogleFonts.outfit(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: AppColors.secondary,
                        ),
                      ),
                            ),
                          );
                        },
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _isUploadingPhoto ? null : _handlePhotoUpload,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: _isUploadingPhoto
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(
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
                _currentUser?.name ?? 'Student',
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _currentUser?.role.name.toUpperCase() ?? 'STUDENT',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              const SizedBox(height: 4),
              if (_currentUser?.studentId != null)
              Text(
                  'Student ID: ${_currentUser!.studentId}',
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

  Widget _buildSafetyScore() {
    // Calculate safety score based on incidents
    int safetyScore = 100 - (_incidentCount * 5).clamp(0, 30);
    safetyScore = safetyScore.clamp(0, 100);
    
    Color scoreColor = safetyScore >= 90 ? AppColors.success :
                       safetyScore >= 75 ? AppColors.secondary :
                       safetyScore >= 60 ? AppColors.warning : AppColors.critical;
    
    String scoreMessage = safetyScore >= 90 ? 'Excellent safety record!' :
                          safetyScore >= 75 ? 'Good safety practices' :
                          safetyScore >= 60 ? 'Fair - be more cautious' : 'Needs improvement';
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              scoreColor.withOpacity(0.2),
              AppColors.secondary.withOpacity(0.2),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: scoreColor, width: 2),
        ),
        child: Row(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: CircularProgressIndicator(
                    value: safetyScore / 100,
                    strokeWidth: 8,
                    backgroundColor: AppColors.border,
                    valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                  ),
                ),
                Column(
                  children: [
                    Text(
                      '$safetyScore',
                      style: GoogleFonts.outfit(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: scoreColor,
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
              ],
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Safety Score',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    scoreMessage,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.foregroundLight,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: scoreColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: scoreColor,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$_incidentCount reports',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: scoreColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Based on activity',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.foregroundLight,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
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
        _buildInfoRow('Residence', _currentUser?.residence ?? 'Not set', Icons.home),
      ],
    );
  }

  Widget _buildEmergencyContacts() {
    return _buildSection(
      'Personal Emergency Contacts',
      Icons.contact_emergency,
      [
        if (_personalContacts.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(
                    Icons.person_add_outlined,
                    size: 48,
                    color: AppColors.foregroundLight.withOpacity(0.5),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No personal contacts added',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.foregroundLight,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _showAddContactDialog,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Contact'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.secondary,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ..._personalContacts.map((contact) => _buildContactCard(contact)),
        if (_personalContacts.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: TextButton.icon(
              onPressed: _showAddContactDialog,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Another Contact'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.secondary,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildContactCard(PersonalContact contact) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: contact.isPrimary ? AppColors.accent : AppColors.border,
          width: contact.isPrimary ? 2 : 1,
        ),
            ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: contact.isPrimary ? AppColors.accent.withOpacity(0.2) : AppColors.secondary.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              contact.isPrimary ? Icons.star : Icons.person,
              color: contact.isPrimary ? AppColors.accent : AppColors.secondary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      contact.name,
            style: GoogleFonts.inter(
                        fontSize: 16,
              fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    if (contact.isPrimary) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'PRIMARY',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  contact.phone,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.foregroundLight,
                  ),
                ),
                if (contact.relationship != null && contact.relationship!.isNotEmpty)
                  Text(
                    contact.relationship!,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.foregroundLight.withOpacity(0.7),
          ),
                  ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppColors.foregroundLight),
            onSelected: (value) async {
              if (value == 'delete') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: AppColors.surface,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    title: Text(
                      'Delete Contact',
                      style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    content: Text(
                      'Are you sure you want to delete ${contact.name}?',
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
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
                
                if (confirm == true) {
                  final success = await _personalContactService.deleteContact(contact.id);
                  if (mounted) {
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Contact deleted successfully',
                            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                          ),
                          backgroundColor: AppColors.success,
                        ),
                      );
                      await _loadUserData();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Failed to delete contact',
                            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                          ),
                          backgroundColor: AppColors.critical,
                        ),
                      );
                    }
                  }
                }
              } else if (value == 'primary') {
                final success = await _personalContactService.updateContact(
                  contactId: contact.id,
                  isPrimary: true,
                );
                if (mounted) {
                  if (success) {
                    await _loadUserData();
                  }
                }
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: contact.isPrimary ? null : 'primary',
                enabled: !contact.isPrimary,
                child: Text(
                  'Set as Primary',
                  style: GoogleFonts.inter(color: Colors.white),
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Text(
                  'Delete',
                  style: GoogleFonts.inter(color: AppColors.critical),
                ),
        ),
      ],
            color: AppColors.surface,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSettings() {
    return _buildSection(
      'Notifications',
      Icons.notifications,
      [
        _buildSwitchRow(
          'Push Notifications',
          'Receive alerts about campus incidents',
          _notificationsEnabled,
          (value) => setState(() => _notificationsEnabled = value),
        ),
        _buildSwitchRow(
          'Buddy Alerts',
          'Get notified when buddies need help',
          _buddyAlertsEnabled,
          (value) => setState(() => _buddyAlertsEnabled = value),
        ),
        _buildInfoRow(
          'Alert Radius',
          '$_safetyRadius km',
          Icons.my_location,
          trailing: IconButton(
            icon: const Icon(Icons.edit, color: AppColors.secondary, size: 20),
            onPressed: () => _showRadiusDialog(),
          ),
        ),
      ],
    );
  }

  Widget _buildPrivacySettings() {
    return _buildSection(
      'Privacy & Security',
      Icons.security,
      [
        _buildSwitchRow(
          'Location Sharing',
          'Share location with buddies',
          _locationSharingEnabled,
          (value) => setState(() => _locationSharingEnabled = value),
        ),
        _buildInfoRow('Default Report Mode', 'Anonymous', Icons.visibility_off),
        _buildInfoRow('Data Retention', '90 days', Icons.timer),
      ],
    );
  }

  Widget _buildActivityHistory() {
    return _buildSection(
      'Activity History',
      Icons.history,
      [
        _buildStatRow('Reports Submitted', '$_incidentCount', AppColors.secondary),
        _buildStatRow('Alerts Received', '0', AppColors.warning),
        _buildStatRow('Check-ins', '0', AppColors.success),
        _buildStatRow('Buddy Connections', '0', AppColors.accent),
      ],
    );
  }

  Widget _buildDangerZone() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.critical.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning, color: AppColors.critical, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Danger Zone',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.critical,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _handleLogout,
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.warning,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: AppColors.secondary, size: 20),
                  ),
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
            const Divider(height: 1, color: AppColors.border),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, {Widget? trailing}) {
    return ListTile(
      leading: Icon(icon, color: AppColors.foregroundLight, size: 20),
      title: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 13,
          color: AppColors.foregroundLight,
        ),
      ),
      subtitle: Text(
        value,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      trailing: trailing,
    );
  }


  Widget _buildSwitchRow(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.inter(
          fontSize: 12,
          color: AppColors.foregroundLight,
        ),
      ),
      activeColor: AppColors.success,
    );
  }

  Widget _buildStatRow(String label, String value, Color color) {
    return ListTile(
      title: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 14,
          color: AppColors.foregroundLight,
        ),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }

  void _showRadiusDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Alert Radius',
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Get notified about incidents within:',
              style: GoogleFonts.inter(color: AppColors.foregroundLight),
            ),
            const SizedBox(height: 20),
            ...['0.5', '1.0', '2.0', '5.0'].map((radius) => RadioListTile<String>(
              value: radius,
              groupValue: _safetyRadius,
              onChanged: (value) {
                setState(() => _safetyRadius = value!);
                Navigator.pop(context);
              },
              title: Text(
                '$radius km',
                style: GoogleFonts.inter(color: Colors.white),
              ),
              activeColor: AppColors.secondary,
            )),
          ],
        ),
      ),
    );
  }

}

