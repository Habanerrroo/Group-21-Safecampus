import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart' as models;

class AdminService {
  final _supabase = Supabase.instance.client;

  Future<Map<String, dynamic>> getDashboardKPIs() async {
    try {
      final allUsersResponse = await _supabase
          .from('users')
          .select('id, role, is_active');

      final allUsersList = allUsersResponse as List;
      final activeUsersList = allUsersList.where((u) {
        if (u is! Map) return false;
        final isActive = u['is_active'];
        return isActive == true || isActive == 1;
      }).toList();

      final totalUsers = allUsersList.length;
      final studentCount = activeUsersList.where((u) => u is Map && u['role'] == 'student').length;
      final securityCount = activeUsersList.where((u) => u is Map && u['role'] == 'security').length;
      final adminCount = activeUsersList.where((u) => u is Map && u['role'] == 'admin').length;

      final incidentsResponse = await _supabase
          .from('incidents')
          .select('id, created_at, status, updated_at');

      final totalIncidents = incidentsResponse.length;
      final activeIncidents = incidentsResponse.where((incident) {
        final status = incident['status'] as String? ?? '';
        return status != 'resolved' && status != 'closed';
      }).length;

      String avgResponseTime = 'N/A';
      try {
        final resolvedIncidents = incidentsResponse.where((incident) {
          return incident['status'] == 'resolved' || incident['status'] == 'closed';
        }).toList();

        if (resolvedIncidents.isNotEmpty) {
          final responseTimes = <Duration>[];
          for (final incident in resolvedIncidents) {
            try {
              final createdAt = DateTime.parse(incident['created_at'] as String);
              final updatedAt = incident['updated_at'] != null
                  ? DateTime.parse(incident['updated_at'] as String)
                  : createdAt;
              final responseTime = updatedAt.difference(createdAt);
              if (responseTime.inMinutes > 0) responseTimes.add(responseTime);
            } catch (e) {
              continue;
            }
          }
          if (responseTimes.isNotEmpty) {
            final avgMinutes = responseTimes.map((d) => d.inMinutes).reduce((a, b) => a + b) / responseTimes.length;
            avgResponseTime = avgMinutes < 60 ? '${avgMinutes.toStringAsFixed(1)}m' : '${(avgMinutes / 60).toStringAsFixed(1)}h';
          }
        }
      } catch (e) {
        // Use N/A if calculation fails
      }

      return {
        'totalUsers': totalUsers,
        'studentCount': studentCount,
        'securityCount': securityCount,
        'adminCount': adminCount,
        'totalIncidents': totalIncidents,
        'activeIncidents': activeIncidents,
        'avgResponseTime': avgResponseTime,
      };
    } catch (e) {
      return {
        'totalUsers': 0,
        'studentCount': 0,
        'securityCount': 0,
        'adminCount': 0,
        'totalIncidents': 0,
        'activeIncidents': 0,
        'avgResponseTime': 'N/A',
      };
    }
  }

  Future<List<models.User>> getAllUsers() async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .order('created_at', ascending: false);

      return (response as List).map((user) {
        return models.User(
          id: user['id'] as String,
          name: user['name'] as String? ?? 'Unknown',
          email: user['email'] as String? ?? '',
          studentId: user['student_id'] as String?,
          phone: user['phone'] as String?,
          residence: user['residence'] as String?,
          role: models.UserRoleExtension.fromString(user['role'] as String? ?? 'student'),
          profileImage: user['profile_image'] as String?,
          createdAt: DateTime.parse(user['created_at'] as String),
          isActive: user['is_active'] as bool? ?? true,
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<bool> updateUserRole({required String userId, required String role}) async {
    try {
      await _supabase
          .from('users')
          .update({'role': role, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', userId);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deactivateUser(String userId) async {
    try {
      await _supabase
          .from('users')
          .update({'is_active': false, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', userId);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> activateUser(String userId) async {
    try {
      await _supabase
          .from('users')
          .update({'is_active': true, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', userId);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> getIncidentAnalytics() async {
    try {
      final response = await _supabase
          .from('incidents')
          .select('type, severity, created_at');

      final typeBreakdown = <String, int>{};
      final severityBreakdown = <String, int>{};
      for (final incident in response) {
        final type = incident['type'] as String? ?? 'other';
        typeBreakdown[type] = (typeBreakdown[type] ?? 0) + 1;
        final severity = incident['severity'] as String? ?? 'medium';
        severityBreakdown[severity] = (severityBreakdown[severity] ?? 0) + 1;
      }

      final now = DateTime.now();
      final weeklyTrend = <int>[];
      for (int i = 6; i >= 0; i--) {
        final dayStart = DateTime(now.year, now.month, now.day - i);
        final dayEnd = dayStart.add(const Duration(days: 1));
        final count = response.where((incident) {
          try {
            final createdAt = DateTime.parse(incident['created_at'] as String);
            return createdAt.isAfter(dayStart) && createdAt.isBefore(dayEnd);
          } catch (e) {
            return false;
          }
        }).length;
        weeklyTrend.add(count);
      }

      return {
        'typeBreakdown': typeBreakdown,
        'severityBreakdown': severityBreakdown,
        'weeklyTrend': weeklyTrend,
        'totalIncidents': response.length,
      };
    } catch (e) {
      return {'typeBreakdown': {}, 'severityBreakdown': {}, 'weeklyTrend': [0, 0, 0, 0, 0, 0, 0], 'totalIncidents': 0};
    }
  }

  Future<List<Map<String, dynamic>>> getRecentActivity({int limit = 10}) async {
    try {
      final incidents = await _supabase
          .from('incidents')
          .select('id, title, created_at')
          .order('created_at', ascending: false)
          .limit(limit);

      final alerts = await _supabase
          .from('alerts')
          .select('id, title, created_at')
          .order('created_at', ascending: false)
          .limit(limit);

      final users = await _supabase
          .from('users')
          .select('id, name, created_at')
          .order('created_at', ascending: false)
          .limit(limit);

      final activities = <Map<String, dynamic>>[];

      for (final incident in incidents) {
        activities.add({'type': 'incident', 'action': 'New incident reported', 'details': incident['title'], 'timestamp': DateTime.parse(incident['created_at']), 'icon': 'report'});
      }
      for (final alert in alerts) {
        activities.add({'type': 'alert', 'action': 'Alert broadcast sent', 'details': alert['title'], 'timestamp': DateTime.parse(alert['created_at']), 'icon': 'notifications'});
      }
      for (final user in users) {
        activities.add({'type': 'user', 'action': 'User registered', 'details': user['name'], 'timestamp': DateTime.parse(user['created_at']), 'icon': 'person_add'});
      }

      activities.sort((a, b) => (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime));
      return activities.take(limit).toList();
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, int>> getUserStatsByRole() async {
    try {
      final response = await _supabase.from('users').select('role').eq('is_active', true);
      final stats = <String, int>{'student': 0, 'security': 0, 'admin': 0};
      for (final user in response) {
        final role = user['role'] as String;
        stats[role] = (stats[role] ?? 0) + 1;
      }
      return stats;
    } catch (e) {
      return {'student': 0, 'security': 0, 'admin': 0};
    }
  }
}