import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import '../../config/theme.dart';
import '../../models/incident.dart';
import '../../models/user.dart' as models;
import '../../widgets/quick_actions.dart';
import '../../widgets/incident_status_manager.dart';
import '../../widgets/officer_location_share.dart';
import '../../services/incident_service.dart';
import '../../services/auth_service.dart';
import '../../services/alert_service.dart';
import '../../services/ai_service.dart';
import 'security_profile.dart';

class EnhancedSecurityDashboard extends StatefulWidget {
  const EnhancedSecurityDashboard({super.key});

  @override
  State<EnhancedSecurityDashboard> createState() => _EnhancedSecurityDashboardState();
}

class _EnhancedSecurityDashboardState extends State<EnhancedSecurityDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Incident? _selectedIncident;
  
  // Services
  final _incidentService = IncidentService();
  final _authService = AuthService();
  final _alertService = AlertService();
  final _aiService = AIService();
  
  // Data
  List<Incident> _incidents = [];
  List<Incident> _myIncidents = [];
  models.User? _currentUser;
  bool _isLoading = true;
  int _activeIncidentCount = 0;
  int _myIncidentCount = 0;
  
  // Realtime subscription
  StreamSubscription? _incidentSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
    _subscribeToIncidents();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _incidentSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      // Get current user
      _currentUser = await _authService.getCurrentUser();
      
      // Get all active incidents
      final allIncidents = await _incidentService.getActiveIncidents();
      
      // AI-powered prioritization
      final prioritized = await _aiService.prioritizeIncidents(allIncidents);
      _incidents = prioritized.map((p) => p['incident'] as Incident).toList();
      _activeIncidentCount = _incidents.length;
      
      // Get incidents assigned to this officer
      if (_currentUser != null) {
        _myIncidents = await _incidentService.getOfficerIncidents(_currentUser!.id);
        _myIncidentCount = _myIncidents.length;
      }
      
      // Select first incident if available
      if (_incidents.isNotEmpty && _selectedIncident == null) {
        _selectedIncident = _incidents.first;
      }
      
    } catch (e) {
      print('[SecurityDashboard] Error loading data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _subscribeToIncidents() {
    _incidentSubscription = _incidentService.subscribeToIncidents().listen((incidents) async {
      if (mounted) {
        final activeIncidents = incidents.where((i) => i.status != 'resolved' && i.status != 'closed').toList();
        
        // AI-powered prioritization
        final prioritized = await _aiService.prioritizeIncidents(activeIncidents);
        final sortedIncidents = prioritized.map((p) => p['incident'] as Incident).toList();
        
        setState(() {
          _incidents = sortedIncidents;
          _activeIncidentCount = _incidents.length;
          
          // Update my incidents
          if (_currentUser != null) {
            _myIncidents = sortedIncidents.where((i) => 
              i.assignedOfficer == _currentUser!.id
            ).toList();
            _myIncidentCount = _myIncidents.length;
          }
        });
      }
    });
  }

  Future<void> _refreshData() async {
    await _loadData();
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.critical,
      ),
    );
  }

  Future<void> _showIncidentDetailsModal(Incident incident) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _getSeverityColor(incident.severity),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              incident.severity.name.toUpperCase(),
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        incident.title,
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildDetailRow('Location', incident.location),
                      _buildDetailRow('Reported', incident.reportedAt),
                      _buildDetailRow('Reported By', incident.reportedBy),
                      _buildDetailRow('Status', incident.status.toUpperCase()),
                      const SizedBox(height: 20),
                      Text(
                        'Description',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.foregroundLight,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        incident.description,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.white,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                Navigator.pop(context);
                                // Auto-assign to current officer
                                if (_currentUser != null) {
                                  await _incidentService.assignIncident(
                                    incidentId: incident.id,
                                    officerId: _currentUser!.id,
                                  );
                                }
                                _tabController.animateTo(2); // Go to Actions tab
                              },
                              icon: const Icon(Icons.touch_app, size: 18),
                              label: const Text('Take Action'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.secondary,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                _handleAssignToMe(incident);
                              },
                              icon: const Icon(Icons.person_add, size: 18),
                              label: const Text('Assign to Me'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.accent,
                                side: const BorderSide(color: AppColors.accent),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleAssignToMe(Incident incident) async {
    if (_currentUser == null) return;

    final success = await _incidentService.assignIncident(
      incidentId: incident.id,
      officerId: _currentUser!.id,
    );

    if (success && mounted) {
      _showSuccessMessage('Incident assigned to you!');
      _refreshData();
    }
  }

  void _showCallDialog(String service, String number) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Call $service',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              service == 'Ambulance' ? Icons.local_hospital : Icons.local_police,
              size: 64,
              color: service == 'Ambulance' ? AppColors.critical : AppColors.warning,
            ),
            const SizedBox(height: 20),
            Text(
              'Calling emergency services',
              style: GoogleFonts.inter(
                color: AppColors.foregroundLight,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              number,
              style: GoogleFonts.robotoMono(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
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
              Navigator.pop(context);
              _showSuccessMessage('Calling $service...');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: service == 'Ambulance' ? AppColors.critical : AppColors.warning,
            ),
            child: const Text('Call'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            
            // Tab Bar
            Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorColor: AppColors.accent,
                labelColor: AppColors.accent,
                unselectedLabelColor: AppColors.foregroundLight,
                labelStyle: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                tabs: const [
                  Tab(text: 'Overview'),
                  Tab(text: 'Incidents'),
                  Tab(text: 'Actions'),
                  Tab(text: 'Location'),
                ],
              ),
            ),
            
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(),
                  _buildIncidentsTab(),
                  _buildActionsTab(),
                  _buildLocationTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final initial = _currentUser?.name.isNotEmpty == true 
        ? _currentUser!.name[0].toUpperCase() 
        : 'O';
    final name = _currentUser?.name ?? 'Officer';
    final badge = _currentUser?.studentId ?? 'Loading...';
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          _currentUser?.profileImage != null && _currentUser!.profileImage!.isNotEmpty
              ? ClipOval(
                  child: Image.network(
                    _currentUser!.profileImage!,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [AppColors.accent, AppColors.accentLight],
                          ),
                        ),
                        child: Center(
                          child: Text(
                            initial,
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                )
              : Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [AppColors.accent, AppColors.accentLight],
                    ),
                  ),
                  child: Center(
                    child: Text(
                      initial,
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'On Duty • Badge #$badge',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.foregroundLight,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.success),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'ACTIVE',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const SecurityProfile()),
                  );
                },
                icon: const Icon(Icons.person, color: Colors.white),
                tooltip: 'Profile',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.secondary));
    }
    
    return RefreshIndicator(
      onRefresh: _refreshData,
      color: AppColors.secondary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatsCards(),
              const SizedBox(height: 24),
              _buildMapSection(),
              const SizedBox(height: 24),
              if (_selectedIncident != null) _buildIncidentDetails(),
              if (_incidents.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      children: [
                        Icon(Icons.check_circle_outline, size: 64, color: AppColors.success),
                        const SizedBox(height: 16),
                        Text(
                          'All Clear',
                          style: GoogleFonts.outfit(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No active incidents at this time',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppColors.foregroundLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIncidentsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.secondary));
    }
    
    return RefreshIndicator(
      onRefresh: _refreshData,
      color: AppColors.secondary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Active Incidents',
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap an incident to view details',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.foregroundLight,
                ),
              ),
              const SizedBox(height: 20),
              if (_incidents.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Text(
                      'No active incidents',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.foregroundLight,
                      ),
                    ),
                  ),
                )
              else
                ..._incidents.map((incident) => _buildIncidentCard(incident)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionsTab() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Manage incident response',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.foregroundLight,
              ),
            ),
            const SizedBox(height: 20),
            
            // Selected Incident Indicator
            if (_selectedIncident != null)
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.accent, width: 2),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.accent, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Selected Incident',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.foregroundLight,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _selectedIncident!.title,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            _selectedIncident!.location,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.foregroundLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() => _selectedIncident = null),
                      icon: const Icon(Icons.close, color: AppColors.foregroundLight, size: 20),
                      tooltip: 'Clear selection',
                    ),
                  ],
                ),
              )
            else
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.warning, width: 1),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'No Incident Selected',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Select an incident from Overview or Incidents tab to use quick actions',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.foregroundLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => _tabController.animateTo(1), // Go to Incidents tab
                      child: const Text('Select'),
                    ),
                  ],
                ),
              ),
            
            QuickActions(
              selectedIncidentId: _selectedIncident?.id,
              onConfirmArrival: () => _handleConfirmArrival(),
              onCallAmbulance: () => _showCallDialog('Ambulance', '911'),
              onCallPolice: () => _showCallDialog('Police', '999'),
              onRequestBackup: () => _handleRequestBackup(),
              onResolveIncident: () => _handleResolveIncident(),
              onShareLocation: () => _showSuccessMessage('Location shared with team!'),
            ),
            
            const SizedBox(height: 24),
            
            if (_selectedIncident != null)
              IncidentStatusManager(
                incidentId: _selectedIncident!.id,
                currentStatus: _parseStatusType(_selectedIncident!.status),
                onStatusChange: (status) => _handleStatusChange(status),
              ),
            
            const SizedBox(height: 24),
            
            // Broadcast Alert Section
            _buildBroadcastAlertSection(),
          ],
        ),
      ),
    );
  }

  Future<void> _handleConfirmArrival() async {
    if (_selectedIncident == null) {
      _showErrorMessage('Please select an incident first');
      return;
    }
    
    final success = await _incidentService.updateIncidentStatus(
      incidentId: _selectedIncident!.id,
      status: 'on-scene',
    );
    
    if (success) {
      _showSuccessMessage('Arrival confirmed!');
      _refreshData();
    } else {
      _showErrorMessage('Failed to confirm arrival');
    }
  }

  Future<void> _handleRequestBackup() async {
    if (_selectedIncident == null) {
      _showErrorMessage('Please select an incident first');
      return;
    }
    
    // Create an alert for backup request
    final alertId = await _alertService.createAlert(
      title: 'Backup Requested',
      message: 'Officer needs backup at ${_selectedIncident!.location}',
      type: 'warning',
      location: _selectedIncident!.location,
    );
    
    if (alertId != null) {
      _showSuccessMessage('Backup requested!');
    } else {
      _showErrorMessage('Failed to request backup');
    }
  }

  Future<void> _handleResolveIncident() async {
    if (_selectedIncident == null) {
      _showErrorMessage('Please select an incident first');
      return;
    }
    
    // Auto-assign if not already assigned
    if (_currentUser != null && (_selectedIncident!.assignedOfficer == null || _selectedIncident!.assignedOfficer!.isEmpty)) {
      await _incidentService.assignIncident(
        incidentId: _selectedIncident!.id,
        officerId: _currentUser!.id,
      );
    }
    
    final success = await _incidentService.updateIncidentStatus(
      incidentId: _selectedIncident!.id,
      status: 'resolved',
    );
    
    if (success) {
      _showSuccessMessage('Incident marked as resolved!');
      _refreshData();
      setState(() => _selectedIncident = null);
    } else {
      _showErrorMessage('Failed to resolve incident');
    }
  }

  Future<void> _handleStatusChange(IncidentStatusType status) async {
    if (_selectedIncident == null) return;
    
    final success = await _incidentService.updateIncidentStatus(
      incidentId: _selectedIncident!.id,
      status: status.name,
    );
    
    if (success) {
      _showSuccessMessage('Status updated to ${status.name}');
      _refreshData();
    }
  }

  IncidentStatusType _parseStatusType(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return IncidentStatusType.reported;
      case 'responding':
        return IncidentStatusType.dispatched;
      case 'investigating':
      case 'on-scene':
        return IncidentStatusType.inProgress;
      case 'resolved':
        return IncidentStatusType.resolved;
      default:
        return IncidentStatusType.reported;
    }
  }

  Widget _buildBroadcastAlertSection() {
    return Container(
      padding: const EdgeInsets.all(20),
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
              Icon(Icons.campaign, color: AppColors.warning, size: 24),
              const SizedBox(width: 12),
              Text(
                'Broadcast Alert',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Send campus-wide safety alerts',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.foregroundLight,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _showBroadcastAlertDialog,
            icon: const Icon(Icons.add_alert),
            label: const Text('Create Alert'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showBroadcastAlertDialog() async {
    final titleController = TextEditingController();
    final messageController = TextEditingController();
    String selectedType = 'warning';
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Broadcast Alert',
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                style: GoogleFonts.inter(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Alert Title',
                  labelStyle: GoogleFonts.inter(color: AppColors.foregroundLight),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: messageController,
                style: GoogleFonts.inter(color: Colors.white),
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Message',
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
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
            child: const Text('Broadcast'),
          ),
        ],
      ),
    );
    
    if (result == true && titleController.text.isNotEmpty && messageController.text.isNotEmpty) {
      final alertId = await _alertService.createAlert(
        title: titleController.text,
        message: messageController.text,
        type: selectedType,
      );
      
      if (alertId != null && mounted) {
        _showSuccessMessage('Alert broadcasted successfully!');
      }
    }
    
    titleController.dispose();
    messageController.dispose();
  }

  Widget _buildLocationTab() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Location Tracking',
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Share your location with dispatch',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.foregroundLight,
              ),
            ),
            const SizedBox(height: 20),
            
            OfficerLocationShare(
              officerId: 'OFF-4567',
              onLocationShared: (position) {
                // Handle location update
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard('Active\nIncidents', '$_activeIncidentCount', Colors.white),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard('My\nCases', '$_myIncidentCount', AppColors.accent),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard('Avg\nResponse', '4.2 min', AppColors.secondary),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color valueColor) {
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
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.foregroundLight,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Campus Map',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Stack(
            children: [
              Center(
                child: Text(
                  'Campus Map View',
                  style: GoogleFonts.inter(color: AppColors.foregroundLight),
                ),
              ),
              ..._incidents.map((incident) {
                if (incident.x == null || incident.y == null) return const SizedBox();
                return Positioned(
                  left: incident.x! * 320,
                  top: incident.y! * 200,
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedIncident = incident),
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: _getSeverityColor(incident.severity),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIncidentDetails() {
    final incident = _selectedIncident!;
    return Container(
      padding: const EdgeInsets.all(20),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getSeverityColor(incident.severity),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  incident.severity.name.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            incident.title,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          _buildDetailRow('Location', incident.location),
          _buildDetailRow('Reported', incident.reportedAt),
          _buildDetailRow('Reported By', incident.reportedBy),
          const SizedBox(height: 12),
          Text(
            incident.description,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.foregroundLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncidentCard(Incident incident) {
    final isSelected = _selectedIncident?.id == incident.id;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? AppColors.accent : AppColors.border,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() => _selectedIncident = incident);
            // Show incident details modal
            _showIncidentDetailsModal(incident);
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getSeverityColor(incident.severity),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        incident.severity.name.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  incident.title,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 14, color: AppColors.secondary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        incident.location,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.foregroundLight,
                        ),
                      ),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.foregroundLight,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getSeverityColor(IncidentSeverity severity) {
    switch (severity) {
      case IncidentSeverity.low:
        return AppColors.info;
      case IncidentSeverity.medium:
        return AppColors.warning;
      case IncidentSeverity.high:
        return AppColors.accent;
      case IncidentSeverity.critical:
        return AppColors.critical;
    }
  }
}

