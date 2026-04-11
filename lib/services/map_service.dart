import 'package:latlong2/latlong.dart';
import 'dart:developer' as developer;
import '../models/incident.dart';

class MapService {
  final _distance = const Distance();

  /// Get the distance between two coordinates in meters
  double getDistance(LatLng point1, LatLng point2) {
    return _distance.as(LengthUnit.Meter, point1, point2);
  }

  /// Get the distance in a human-readable format
  String getDistanceString(LatLng point1, LatLng point2) {
    final distance = getDistance(point1, point2);
    if (distance < 1000) {
      return '${distance.toStringAsFixed(0)}m';
    } else {
      return '${(distance / 1000).toStringAsFixed(1)}km';
    }
  }

  /// Convert incident coordinates to LatLng
  LatLng? incidentToLatLng(Incident incident) {
    if (incident.x != null && incident.y != null) {
      return LatLng(incident.x!, incident.y!);
    }
    return null;
  }

  /// Get initial map center (default campus location)
  /// You can update this to your actual campus coordinates
  LatLng getDefaultCenter() {
    // Default coordinates (update with your campus location)
    return const LatLng(6.5244, 3.3792); // Example: Lagos, Nigeria
  }

  /// Calculate route between two points (simplified - for actual routing, use a routing service)
  List<LatLng> calculateRoute(LatLng start, LatLng end) {
    // This is a simplified straight-line route
    // For actual turn-by-turn navigation, integrate with a routing API like OSRM or Mapbox
    return [start, end];
  }

  /// Get bearing (direction) from point1 to point2 in degrees
  double getBearing(LatLng point1, LatLng point2) {
    return _distance.bearing(point1, point2);
  }

  /// Format bearing as compass direction
  String getBearingString(LatLng point1, LatLng point2) {
    final bearing = getBearing(point1, point2);
    final directions = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    final index = ((bearing + 22.5) / 45).floor() % 8;
    return directions[index];
  }
}
