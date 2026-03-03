class Alert {
  final String id;
  final String title;
  final String message;
  final AlertType type;
  final String timestamp;
  final String? distance;
  final bool isRead;

  Alert({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    this.distance,
    this.isRead = false,
  });
}

enum AlertType {
  critical,
  warning,
  info,
  allClear,
}

