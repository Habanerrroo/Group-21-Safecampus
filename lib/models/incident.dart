enum IncidentSeverity { low, medium, high, critical }

class Incident {
  final String id;
  final String title;
  final String description;
  final String location;
  final String reportedAt;
  final String reportedBy;
  final String status;
  final IncidentSeverity severity;
  final String? assignedOfficer;
  final double? x;
  final double? y;

  Incident({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.reportedAt,
    required this.reportedBy,
    required this.status,
    required this.severity,
    this.assignedOfficer,
    this.x,
    this.y,
  });
}
