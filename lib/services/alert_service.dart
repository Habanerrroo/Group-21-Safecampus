import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:developer' as developer;
import '../models/alert.dart';

class AlertService {
  final _supabase = Supabase.instance.client;

  // Fetch all active alerts
  Future<List<Alert>> getActiveAlerts({String? userId}) async {
    developer.log('🔔 FETCHING ACTIVE ALERTS', name: 'AlertService');
    if (userId != null) {
      developer.log('👤 User ID: $userId (checking read status)', name: 'AlertService');
    }

    try {
      final response = await _supabase
          .from('alerts')
          .select()
          .eq('is_active', true)
          .order('created_at', ascending: false);

      developer.log('✅ Fetched ${response.length} alerts', name: 'AlertService');

      // Get read alerts for this user if userId provided
      Set<String> readAlertIds = {};
      if (userId != null) {
        try {
          final readAlerts = await _supabase
              .from('alert_reads')
              .select('alert_id')
              .eq('user_id', userId);
          
          readAlertIds = (readAlerts as List).map((r) => r['alert_id'] as String).toSet();
          developer.log('📖 Found ${readAlertIds.length} read alerts for user', name: 'AlertService');
        } catch (e) {
          developer.log('⚠️ Error fetching read alerts: $e', name: 'AlertService');
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
          distance: null, // Will calculate based on location if needed
          isRead: userId != null ? readAlertIds.contains(alertId) : false,
        );
      }).toList();
    } catch (e) {
      developer.log('❌ Error fetching alerts: $e', name: 'AlertService');
      return [];
    }
  }

  // Mark alert as read
  Future<bool> markAlertAsRead(String alertId, String userId) async {
    developer.log('✅ MARKING ALERT AS READ', name: 'AlertService');
    developer.log('🔔 Alert ID: $alertId', name: 'AlertService');
    developer.log('👤 User ID: $userId', name: 'AlertService');

    try {
      // Use upsert to handle duplicate key constraint
      // If already exists, just update the read_at timestamp
      await _supabase.from('alert_reads').upsert({
        'alert_id': alertId,
        'user_id': userId,
        'read_at': DateTime.now().toIso8601String(),
      }, onConflict: 'alert_id,user_id');

      developer.log('✅ Alert marked as read', name: 'AlertService');
      return true;
    } catch (e) {
      developer.log('❌ Error marking alert as read: $e', name: 'AlertService');
      return false;
    }
  }

  // Get unread alert count for user
  Future<int> getUnreadCount(String userId) async {
    developer.log('🔔 GETTING UNREAD COUNT', name: 'AlertService');

    try {
      // Get all active alerts
      final alerts = await _supabase
          .from('alerts')
          .select('id')
          .eq('is_active', true);

      // Get read alerts for this user
      final readAlerts = await _supabase
          .from('alert_reads')
          .select('alert_id')
          .eq('user_id', userId);

      final readAlertIds = (readAlerts as List).map((r) => r['alert_id']).toSet();
      final unreadCount = alerts.length - readAlertIds.length;

      developer.log('✅ Unread count: $unreadCount', name: 'AlertService');
      return unreadCount;
    } catch (e) {
      developer.log('❌ Error getting unread count: $e', name: 'AlertService');
      return 0;
    }
  }

  // Create/broadcast a new alert (for security/admin)
  Future<String?> createAlert({
    required String title,
    required String message,
    required String type,
    String? location,
    double? latitude,
    double? longitude,
  }) async {
    developer.log('📢 CREATING ALERT', name: 'AlertService');
    developer.log('📋 Title: $title', name: 'AlertService');
    developer.log('🏷️ Type: $type', name: 'AlertService');

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

      developer.log('📋 Alert data: $alertData', name: 'AlertService');

      final response = await _supabase
          .from('alerts')
          .insert(alertData)
          .select('id')
          .single();

      final alertId = response['id'];
      developer.log('✅ Alert created with ID: $alertId', name: 'AlertService');

      return alertId;
    } catch (e) {
      developer.log('❌ Error creating alert: $e', name: 'AlertService');
      return null;
    }
  }

  // Deactivate an alert
  Future<bool> deactivateAlert(String alertId) async {
    developer.log('🔕 DEACTIVATING ALERT', name: 'AlertService');
    developer.log('🆔 Alert ID: $alertId', name: 'AlertService');

    try {
      await _supabase
          .from('alerts')
          .update({
            'is_active': false,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', alertId);

      developer.log('✅ Alert deactivated', name: 'AlertService');
      return true;
    } catch (e) {
      developer.log('❌ Error deactivating alert: $e', name: 'AlertService');
      return false;
    }
  }

  // Subscribe to real-time alerts
  RealtimeChannel subscribeToAlerts(Function(Alert) onNewAlert) {
    developer.log('📡 SUBSCRIBING TO REAL-TIME ALERTS', name: 'AlertService');

    return _supabase
        .channel('alerts')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'alerts',
          callback: (payload) {
            developer.log('🔔 New alert received', name: 'AlertService');
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

  // Helper methods
  AlertType _parseAlertType(String type) {
    switch (type.toLowerCase()) {
      case 'critical':
        return AlertType.critical;
      case 'warning':
        return AlertType.warning;
      case 'info':
        return AlertType.info;
      case 'allclear':
        return AlertType.allClear;
      default:
        return AlertType.info;
    }
  }

  String _formatTimestamp(String timestamp) {
    try {
      final date = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes} minutes ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours} hours ago';
      } else {
        return '${difference.inDays} days ago';
      }
    } catch (e) {
      return timestamp;
    }
  }
}

