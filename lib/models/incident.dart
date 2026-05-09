class Incident {
  final String id;
  final String title;
  final IncidentType type;
  final IncidentSeverity severity;
  final String status;
  final String location;
  final String reportedAt;
  final String reportedBy;
  final String description;
  final List<String> images;
  final List<TimelineItem> timeline;
  final String? assignedOfficer;
  final String? notes;
  final double? x;
  final double? y;

  Incident({
    required this.id,
    required this.title,
    required this.type,
    required this.severity,
    required this.status,
    required this.location,
    required this.reportedAt,
    required this.reportedBy,
    required this.description,
    this.images = const [],
    this.timeline = const [],
    this.assignedOfficer,
    this.notes,
    this.x,
    this.y,
  });
}

enum IncidentType {
  theft,
  assault,
  harassment,
  fire,
  medical,
  other,
}

enum IncidentSeverity {
  low,
  medium,
  high,
  critical,
}

class TimelineItem {
  final String time;
  final String action;
  final TimelineStatus status;

  TimelineItem({
    required this.time,
    required this.action,
    required this.status,
  });
}

enum TimelineStatus {
  completed,
  inProgress,
  pending,
}

