import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/alert.dart';

class AlertService {
  final _supabase = Supabase.instance.client;

  Future<List<Alert>> getActiveAlerts({String? userId}) async {
    try {
      final response = await _supabase
          .from('alerts')
          .select()
          .eq('is_active', true)
          .order('created_at', ascending: false);

      Set<String> readAlertIds = {};
      if (userId != null) {
        try {
          final readAlerts = await _supabase
              .from('alert_reads')
              .select('alert_id')
              .eq('user_id', userId);
          readAlertIds = (readAlerts as List).map((r) => r['alert_id'] as String).toSet();
        } catch (e) {
          // ignore read status errors
        }
      }

      return (response as List).map((alert) {
        final alertId = alert['id'] as String;
        return Alert(
          id: alertId,
          title: alert['title'],
          message: alert['message'],
          type: _parseAlertType(alert['type']),
          timestamp: _formatTimestamp(alert['created_at']),
          distance: null,
          isRead: userId != null ? readAlertIds.contains(alertId) : false,
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<bool> markAlertAsRead(String alertId, String userId) async {
    try {
      await _supabase.from('alert_reads').upsert({
        'alert_id': alertId,
        'user_id': userId,
        'read_at': DateTime.now().toIso8601String(),
      }, onConflict: 'alert_id,user_id');
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<int> getUnreadCount(String userId) async {
    try {
      final alerts = await _supabase
          .from('alerts')
          .select('id')
          .eq('is_active', true);

      final readAlerts = await _supabase
          .from('alert_reads')
          .select('alert_id')
          .eq('user_id', userId);

      final readAlertIds = (readAlerts as List).map((r) => r['alert_id']).toSet();
      return alerts.length - readAlertIds.length;
    } catch (e) {
      return 0;
    }
  }

  Future<String?> createAlert({
    required String title,
    required String message,
    required String type,
    String? location,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final currentUser = _supabase.auth.currentUser;

      final alertData = {
        'title': title,
        'message': message,
        'type': type,
        'latitude': latitude,
        'longitude': longitude,
        'is_active': true,
        'created_by': currentUser?.id,
        'created_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('alerts')
          .insert(alertData)
          .select('id')
          .single();

      return response['id'];
    } catch (e) {
      return null;
    }
  }

  Future<bool> deactivateAlert(String alertId) async {
    try {
      await _supabase
          .from('alerts')
          .update({'is_active': false})
          .eq('id', alertId);
      return true;
    } catch (e) {
      return false;
    }
  }

  RealtimeChannel subscribeToAlerts(Function(Alert) onNewAlert) {
    return _supabase
        .channel('alerts')
        .onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'alerts',
      callback: (payload) {
        final alert = Alert(
          id: payload.newRecord['id'],
          title: payload.newRecord['title'],
          message: payload.newRecord['message'],
          type: _parseAlertType(payload.newRecord['type']),
          timestamp: _formatTimestamp(payload.newRecord['created_at']),
          isRead: false,
        );
        onNewAlert(alert);
      },
    )
        .subscribe();
  }

  AlertType _parseAlertType(String type) {
    switch (type.toLowerCase()) {
      case 'critical': return AlertType.critical;
      case 'warning': return AlertType.warning;
      case 'info': return AlertType.info;
      case 'allclear': return AlertType.allClear;
      default: return AlertType.info;
    }
  }

  String _formatTimestamp(String timestamp) {
    try {
      final date = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inMinutes < 1) return 'Just now';
      if (difference.inMinutes < 60) return '${difference.inMinutes} minutes ago';
      if (difference.inHours < 24) return '${difference.inHours} hours ago';
      return '${difference.inDays} days ago';
    } catch (e) {
      return timestamp;
    }
  }
}