import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:developer' as developer;
import '../../config/theme.dart';
import '../../models/alert.dart';
import '../../models/user.dart' as models;
import '../../services/user_service.dart';
import '../../services/alert_service.dart';
import '../../services/incident_service.dart';
import '../../services/buddy_service.dart';
import '../../widgets/student_header.dart';
import '../../widgets/emergency_button.dart';
import '../../widgets/alert_card.dart';
import '../../widgets/emergency_contacts.dart';
import '../../widgets/safety_dashboard.dart';
import 'incident_composer_screen.dart';
import 'student_profile.dart';

class EnhancedStudentDashboard extends StatefulWidget {
  const EnhancedStudentDashboard({super.key});

  @override
  State<EnhancedStudentDashboard> createState() => _EnhancedStudentDashboardState();
}

class _EnhancedStudentDashboardState extends State<EnhancedStudentDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _submitted = false;

  // Services
  final _userService = UserService();
  final _alertService = AlertService();
  final _incidentService = IncidentService();
  final _buddyService = BuddyService();
  
  // Data
  models.User? _currentUser;
  List<Alert> _alerts = [];
  int _unreadCount = 0;
  int _incidentCount = 0;
  bool _isLoading = true;
  RealtimeChannel? _alertChannel;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadData();
    _subscribeToAlerts();
  }
  
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    // Load user data
    _currentUser = await _userService.getCurrentUser();
    
    // Load alerts with read status
    _alerts = await _alertService.getActiveAlerts(userId: _currentUser?.id);
    
    // Get unread count and incident count
    if (_currentUser != null) {
      _unreadCount = await _alertService.getUnreadCount(_currentUser!.id);
      final incidents = await _incidentService.getUserIncidents(_currentUser!.id);
      _incidentCount = incidents.length;
    }
    
    setState(() => _isLoading = false);
  }
  
  void _subscribeToAlerts() {
    _alertChannel = _alertService.subscribeToAlerts((newAlert) {
      setState(() {
        _alerts.insert(0, newAlert);
        _unreadCount++;
      });
      
      // Show snackbar for new alert
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('New ${newAlert.type.name} alert: ${newAlert.title}'),
            backgroundColor: _getAlertColor(newAlert.type),
            action: SnackBarAction(
              label: 'View',
              textColor: Colors.white,
              onPressed: () {
                _tabController.animateTo(1); // Go to alerts tab
              },
            ),
          ),
        );
      }
    });
  }
  
  Color _getAlertColor(AlertType type) {
    switch (type) {
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

  @override
  void dispose() {
    _tabController.dispose();
    _alertChannel?.unsubscribe();
    super.dispose();
  }

  void _handleReportSubmit() {
    setState(() => _submitted = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _submitted = false;
          _tabController.animateTo(0);
        });
        // Reload data after incident submission
        _loadData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            StudentHeader(
              userName: _currentUser?.name.split(' ').first ?? 'Student',
              unreadCount: _unreadCount,
              profileImageUrl: _currentUser?.profileImage,
              onNotifications: () {
                _tabController.animateTo(1); // Go to alerts tab
              },
              onProfile: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StudentProfile(user: _currentUser),
                  ),
                ).then((_) => _loadData()); // Reload data when returning
              },
            ),
            
            // Tab Bar
            Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  bottom: BorderSide(color: AppColors.border),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorColor: AppColors.secondary,
                labelColor: AppColors.secondary,
                unselectedLabelColor: AppColors.foregroundLight,
                labelStyle: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                tabs: const [
                  Tab(text: 'Home'),
                  Tab(text: 'Alerts'),
                  Tab(text: 'Report'),
                  Tab(text: 'Buddies'),
                  Tab(text: 'Contacts'),
                ],
              ),
            ),
            
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildHomeTab(),
                  _buildAlertsTab(),
                  _buildReportTab(),
                  _buildBuddiesTab(),
                  _buildContactsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeTab() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Emergency Section
            Container(
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
                    'Press and hold for 3 seconds',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.foregroundLight,
                    ),
                  ),
                  const SizedBox(height: 24),
                  EmergencyButton(
                    onActivate: () async {
                      // Create emergency incident
                      if (_currentUser != null) {
                        try {
                          developer.log('🚨 EMERGENCY SOS ACTIVATED', name: 'StudentDashboard');
                          developer.log('👤 User: ${_currentUser!.name} (${_currentUser!.id})', name: 'StudentDashboard');
                          
                          // Get location - use residence as primary, GPS as fallback
                          String location = _currentUser?.residence ?? 'Location not set';
                          double? latitude;
                          double? longitude;
                          
                          // Try to get GPS coordinates if available (optional enhancement)
                          try {
                            bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
                            if (serviceEnabled) {
                              LocationPermission permission = await Geolocator.checkPermission();
                              if (permission == LocationPermission.denied) {
                                permission = await Geolocator.requestPermission();
                              }
                              
                              if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
                                Position position = await Geolocator.getCurrentPosition(
                                  desiredAccuracy: LocationAccuracy.high,
                                  timeLimit: const Duration(seconds: 5), // Don't wait too long
                                );
                                latitude = position.latitude;
                                longitude = position.longitude;
                                // Keep residence as location text, but add GPS coords
                                developer.log('📍 GPS coordinates obtained: $latitude, $longitude', name: 'StudentDashboard');
                              }
                            }
                          } catch (e) {
                            // GPS failed, but that's okay - we have residence
                            developer.log('⚠️ GPS unavailable, using residence: ${_currentUser?.residence}', name: 'StudentDashboard');
                          }
                          
                          final incidentId = await _incidentService.createIncident(
                            title: 'EMERGENCY SOS - Immediate Assistance Required',
                            type: 'emergency', // Emergency type
                            severity: 'critical',
                            location: location,
                            description: 'Emergency SOS activated by ${_currentUser!.name}. Immediate assistance required.',
                            isAnonymous: false,
                            latitude: latitude,
                            longitude: longitude,
                          );
                          
                          developer.log('🆔 Incident ID returned: $incidentId', name: 'StudentDashboard');
                          
                          if (incidentId != null && mounted) {
                            developer.log('✅ SOS incident created successfully', name: 'StudentDashboard');
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Emergency SOS sent! Security has been notified.',
                                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                                ),
                                backgroundColor: AppColors.success,
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 5),
                              ),
                            );
                            // Refresh data to show new incident
                            _loadData();
                          } else {
                            developer.log('❌ SOS incident creation failed - incidentId is null', name: 'StudentDashboard');
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Failed to send SOS. Please try again or call emergency services directly.',
                                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                                  ),
                                  backgroundColor: AppColors.critical,
                                  behavior: SnackBarBehavior.floating,
                                  duration: const Duration(seconds: 5),
                                ),
                              );
                            }
                          }
                        } catch (e, stackTrace) {
                          developer.log('❌ ERROR in SOS button: $e', name: 'StudentDashboard');
                          developer.log('📚 Stack trace: $stackTrace', name: 'StudentDashboard');
                          if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                                  'Error sending SOS: ${e.toString()}. Please call emergency services directly.',
                            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                          ),
                                backgroundColor: AppColors.critical,
                          behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 5),
                        ),
                      );
                          }
                        }
                      } else {
                        developer.log('❌ SOS failed - _currentUser is null', name: 'StudentDashboard');
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Safety Dashboard
            SafetyDashboard(
              incidentCount: _incidentCount,
              alertCount: _alerts.length,
              checkInCount: 0, // Will integrate buddy check-ins later
            ),
            const SizedBox(height: 24),
            
            // Recent Alerts Preview
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Alerts',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                TextButton(
                  onPressed: () => _tabController.animateTo(1),
                  child: Text(
                    'View All',
                    style: GoogleFonts.inter(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._alerts.take(2).map((alert) => AlertCard(alert: alert)),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertsTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Safety Alerts',
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
                      const SizedBox(height: 4),
            Text(
              'Stay informed about campus safety',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.foregroundLight,
              ),
                      ),
                    ],
                  ),
                  if (_unreadCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$_unreadCount new',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
            ),
            const SizedBox(height: 20),
              if (_alerts.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      children: [
                        Icon(
                          Icons.notifications_none,
                          size: 64,
                          color: AppColors.foregroundLight,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No alerts at this time',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: AppColors.foregroundLight,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'You\'ll be notified of any safety updates',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppColors.foregroundLight.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ..._alerts.map((alert) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AlertCard(
                    alert: alert,
                    onTap: () async {
                      // Mark as read
                      if (_currentUser != null && !alert.isRead) {
                        final success = await _alertService.markAlertAsRead(alert.id, _currentUser!.id);
                        if (success && mounted) {
                          setState(() {
                            // Update the alert's read status in the list
                            final index = _alerts.indexWhere((a) => a.id == alert.id);
                            if (index != -1) {
                              _alerts[index] = Alert(
                                id: alert.id,
                                title: alert.title,
                                message: alert.message,
                                type: alert.type,
                                timestamp: alert.timestamp,
                                distance: alert.distance,
                                isRead: true,
                              );
                            }
                            _unreadCount = (_unreadCount - 1).clamp(0, 999);
                          });
                        }
                      }
                    },
                  ),
                )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportTab() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: _submitted
            ? Container(
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
              )
            : IncidentComposerScreen(
                onSubmit: _handleReportSubmit,
              ),
      ),
    );
  }

  Widget _buildBuddiesTab() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
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
                  onPressed: () => _showAddBuddyDialog(),
                  icon: const Icon(Icons.person_add, size: 18),
                  label: const Text('Add Buddy'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Pending Requests
            FutureBuilder<List<BuddyConnection>>(
              future: _buddyService.getPendingRequests(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final pending = snapshot.data ?? [];
                if (pending.isNotEmpty) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pending Requests (${pending.length})',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.warning,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...pending.map((request) => _buildPendingRequestCard(request)),
                      const SizedBox(height: 24),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            
            // My Buddies
            FutureBuilder<List<BuddyConnection>>(
              future: _buddyService.getBuddyConnections(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final buddies = snapshot.data ?? [];
                if (buddies.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 64,
                            color: AppColors.foregroundLight.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No buddies yet',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              color: AppColors.foregroundLight,
              ),
            ),
            const SizedBox(height: 8),
            Text(
                            'Add friends to keep track of each other\'s safety',
                            textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                              color: AppColors.foregroundLight.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Buddies (${buddies.length})',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...buddies.map((buddy) => _buildBuddyCard(buddy)),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPendingRequestCard(BuddyConnection request) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.warning.withOpacity(0.2),
              child: Icon(Icons.person, color: AppColors.warning),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.buddy?.name ?? 'Unknown',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (request.buddy?.email != null)
                    Text(
                      request.buddy!.email,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.foregroundLight,
                      ),
                    ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => _handleRejectRequest(request.id),
              child: Text('Reject', style: GoogleFonts.inter(color: AppColors.critical)),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => _handleAcceptRequest(request.id),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
              child: const Text('Accept'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildBuddyCard(BuddyConnection buddy) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.secondary.withOpacity(0.2),
              child: Icon(Icons.person, color: AppColors.secondary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    buddy.buddy?.name ?? 'Unknown',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (buddy.buddy?.email != null)
                    Text(
                      buddy.buddy!.email,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                color: AppColors.foregroundLight,
              ),
            ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => _handleRemoveBuddy(buddy.id),
              icon: const Icon(Icons.delete_outline, color: AppColors.critical),
              tooltip: 'Remove buddy',
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _showAddBuddyDialog() async {
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        final emailController = TextEditingController();
        
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(
            'Add Buddy',
            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: emailController,
            autofocus: true,
            style: GoogleFonts.inter(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Buddy Email',
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
            keyboardType: TextInputType.emailAddress,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, null),
              child: Text('Cancel', style: GoogleFonts.inter(color: AppColors.foregroundLight)),
            ),
            ElevatedButton(
              onPressed: () {
                final email = emailController.text.trim();
                Navigator.pop(dialogContext, email);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
              child: const Text('Send Request'),
            ),
          ],
        );
      },
    );
    
    if (result != null && result.isNotEmpty) {
      final error = await _buddyService.sendBuddyRequest(result);
      if (mounted) {
        if (error == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Buddy request sent!',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
              backgroundColor: AppColors.success,
            ),
          );
          setState(() {}); // Refresh
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                error,
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
              backgroundColor: AppColors.critical,
            ),
          );
        }
      }
    }
  }
  
  Future<void> _handleAcceptRequest(String connectionId) async {
    final success = await _buddyService.acceptBuddyRequest(connectionId);
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Buddy request accepted!',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            backgroundColor: AppColors.success,
          ),
        );
        setState(() {}); // Refresh
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to accept request',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            backgroundColor: AppColors.critical,
          ),
        );
      }
    }
  }
  
  Future<void> _handleRejectRequest(String connectionId) async {
    final success = await _buddyService.rejectBuddyRequest(connectionId);
    if (mounted) {
      if (success) {
        setState(() {}); // Refresh
      }
    }
  }
  
  Future<void> _handleRemoveBuddy(String connectionId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Remove Buddy?',
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to remove this buddy?',
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
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      final success = await _buddyService.removeBuddy(connectionId);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Buddy removed',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
              backgroundColor: AppColors.success,
            ),
          );
          setState(() {}); // Refresh
        }
      }
    }
  }

  Widget _buildContactsTab() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Get Help Fast',
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Quick access to emergency services',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.foregroundLight,
              ),
            ),
            const SizedBox(height: 24),
            EmergencyContacts(),
          ],
        ),
      ),
    );
  }
}

