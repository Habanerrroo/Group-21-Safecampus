class Dispatch {
  final String id;
  final String type;
  final DispatchPriority priority;
  final DispatchStatus status;
  final String location;
  final String eta;
  final List<String> officers;

  Dispatch({
    required this.id,
    required this.type,
    required this.priority,
    required this.status,
    required this.location,
    required this.eta,
    required this.officers,
  });
}

enum DispatchPriority {
  low,
  medium,
  high,
}

enum DispatchStatus {
  dispatched,
  enRoute,
  onScene,
  completed,
}

