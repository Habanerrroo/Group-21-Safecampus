import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../models/incident.dart';
import '../../models/dispatch.dart';

class SecurityDashboard extends StatefulWidget {
  const SecurityDashboard({super.key});

  @override
  State<SecurityDashboard> createState() => _SecurityDashboardState();
}

class _SecurityDashboardState extends State<SecurityDashboard> {
  Incident? _selectedIncident;

  final List<Incident> mockIncidents = [
    Incident(
      id: 'INC-2024-001',
      title: 'Assault Report - Library',
      type: IncidentType.assault,
      severity: IncidentSeverity.high,
      status: 'responding',
      location: 'Library Entrance',
      reportedAt: '2:15 PM - Today',
      reportedBy: 'Anonymous',
      description: 'Assault reported near library entrance',
      x: 0.25,
      y: 0.30,
    ),
    Incident(
      id: 'INC-2024-002',
      title: 'Theft - Parking Lot',
      type: IncidentType.theft,
      severity: IncidentSeverity.medium,
      status: 'investigating',
      location: 'Parking Lot B',
      reportedAt: '1:45 PM - Today',
      reportedBy: 'Student',
      description: 'Laptop stolen from vehicle',
      x: 0.65,
      y: 0.45,
    ),
    Incident(
      id: 'INC-2024-003',
      title: 'Medical Emergency - Student Center',
      type: IncidentType.medical,
      severity: IncidentSeverity.critical,
      status: 'on-scene',
      location: 'Student Center - Building A, 2nd Floor',
      reportedAt: '2:15 PM - Today',
      reportedBy: 'Anonymous Call',
      description: 'Student collapsed near the cafeteria. Currently responsive.',
      x: 0.40,
      y: 0.60,
      timeline: [
        TimelineItem(
          time: '2:15 PM',
          action: 'Emergency call received',
          status: TimelineStatus.completed,
        ),
        TimelineItem(
          time: '2:17 PM',
          action: 'Medical team dispatched',
          status: TimelineStatus.completed,
        ),
        TimelineItem(
          time: '2:22 PM',
          action: 'Arrival on scene',
          status: TimelineStatus.completed,
        ),
        TimelineItem(
          time: '2:25 PM',
          action: 'Patient assessment underway',
          status: TimelineStatus.inProgress,
        ),
      ],
      assignedOfficer: 'Dr. Patricia Chen, EMT',
      notes: 'Patient vitals stable. Transferring to campus health center.',
    ),
  ];

  final List<Dispatch> mockDispatches = [
    Dispatch(
      id: 'DISP-001',
      type: 'Medical Response Unit',
      priority: DispatchPriority.high,
      status: DispatchStatus.onScene,
      location: 'Student Center',
      eta: '2 min',
      officers: ['Martinez', 'Chen'],
    ),
    Dispatch(
      id: 'DISP-002',
      type: 'Security Patrol',
      priority: DispatchPriority.high,
      status: DispatchStatus.enRoute,
      location: 'Library Entrance',
      eta: '5 min',
      officers: ['Williams', 'Lee'],
    ),
    Dispatch(
      id: 'DISP-003',
      type: 'Patrol Unit',
      priority: DispatchPriority.medium,
      status: DispatchStatus.dispatched,
      location: 'Parking Lot B',
      eta: '8 min',
      officers: ['Garcia'],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIncident = mockIncidents[2]; // Select medical emergency by default
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatsCards(),
                      const SizedBox(height: 24),
                      _buildMapSection(),
                      const SizedBox(height: 24),
                      if (_selectedIncident != null) ...[
                        _buildIncidentDetails(),
                        const SizedBox(height: 24),
                      ],
                      _buildDispatchBoard(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Command Center',
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            'Real-time Campus Security Operations',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.foregroundLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard('Active\nIncidents', '${mockIncidents.length}', Colors.white),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard('Units\nDeployed', '${mockDispatches.length}', Colors.white),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard('Avg Response', '4.2 min', AppColors.secondary),
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
          height: 250,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Stack(
            children: [
              // Map background
              Center(
                child: Text(
                  'Campus Map View',
                  style: GoogleFonts.inter(
                    color: AppColors.foregroundLight,
                  ),
                ),
              ),
              // Incident markers
              ...mockIncidents.map((incident) {
                if (incident.x == null || incident.y == null) return const SizedBox();
                return Positioned(
                  left: incident.x! * 350,
                  top: incident.y! * 250,
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedIncident = incident),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _getSeverityColor(incident.severity),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: _getSeverityColor(incident.severity).withOpacity(0.5),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          _getIncidentIcon(incident.type),
                          style: const TextStyle(fontSize: 16),
                        ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Incident Details',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            IconButton(
              onPressed: () => setState(() => _selectedIncident = null),
              icon: const Icon(Icons.close, color: AppColors.foregroundLight),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
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
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    incident.id,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.foregroundLight,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                incident.title,
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              _buildDetailRow('Location', incident.location),
              _buildDetailRow('Reported', incident.reportedAt),
              _buildDetailRow('Reported By', incident.reportedBy),
              if (incident.assignedOfficer != null)
                _buildDetailRow('Assigned', incident.assignedOfficer!),
              const SizedBox(height: 12),
              Text(
                incident.description,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.foregroundLight,
                  height: 1.5,
                ),
              ),
              if (incident.timeline.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Divider(color: AppColors.border),
                const SizedBox(height: 12),
                Text(
                  'Timeline',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                ...incident.timeline.map((item) => _buildTimelineItem(item)),
              ],
            ],
          ),
        ),
      ],
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
                fontSize: 14,
                color: AppColors.foregroundLight,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(TimelineItem item) {
    Color statusColor;
    switch (item.status) {
      case TimelineStatus.completed:
        statusColor = AppColors.success;
        break;
      case TimelineStatus.inProgress:
        statusColor = AppColors.accent;
        break;
      case TimelineStatus.pending:
        statusColor = AppColors.foregroundLight;
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.action,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  item.time,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.foregroundLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDispatchBoard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Active Dispatch',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        ...mockDispatches.map((dispatch) => _buildDispatchCard(dispatch)),
      ],
    );
  }

  Widget _buildDispatchCard(Dispatch dispatch) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getDispatchPriorityColor(dispatch.priority),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  dispatch.priority.name.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getDispatchStatusColor(dispatch.status),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  dispatch.status.name.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            dispatch.type,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on, size: 16, color: AppColors.secondary),
              const SizedBox(width: 4),
              Text(
                dispatch.location,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.foregroundLight,
                ),
              ),
              const Spacer(),
              Text(
                'ETA: ${dispatch.eta}',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Officers: ${dispatch.officers.join(", ")}',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.foregroundLight,
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

  Color _getDispatchPriorityColor(DispatchPriority priority) {
    switch (priority) {
      case DispatchPriority.low:
        return AppColors.info;
      case DispatchPriority.medium:
        return AppColors.warning;
      case DispatchPriority.high:
        return AppColors.accent;
    }
  }

  Color _getDispatchStatusColor(DispatchStatus status) {
    switch (status) {
      case DispatchStatus.dispatched:
        return AppColors.foregroundLight;
      case DispatchStatus.enRoute:
        return AppColors.warning;
      case DispatchStatus.onScene:
        return AppColors.success;
      case DispatchStatus.completed:
        return AppColors.success;
    }
  }

  String _getIncidentIcon(IncidentType type) {
    switch (type) {
      case IncidentType.theft:
        return '🎒';
      case IncidentType.assault:
        return '⚠️';
      case IncidentType.harassment:
        return '🚫';
      case IncidentType.fire:
        return '🔥';
      case IncidentType.medical:
        return '🏥';
      case IncidentType.other:
        return '📝';
    }
  }
}

