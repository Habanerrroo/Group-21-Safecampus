import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:developer' as developer;
import '../models/user.dart' as models;

class AdminService {
  final _supabase = Supabase.instance.client;

  // Get dashboard KPIs
  Future<Map<String, dynamic>> getDashboardKPIs() async {
    developer.log('📊 FETCHING DASHBOARD KPIs', name: 'AdminService');

    try {
      // Get ALL users (not just active) for total count
      developer.log('📊 Fetching all users...', name: 'AdminService');
      
      // Get all users with their data
      final allUsersResponse = await _supabase
          .from('users')
          .select('id, role, is_active');
      
      // Supabase returns a List directly
      final allUsersList = allUsersResponse as List;
      
      developer.log('📊 Users list length: ${allUsersList.length}', name: 'AdminService');
      
      // Get active users for role breakdown
      final activeUsersList = allUsersList
          .where((u) {
            if (u is! Map) return false;
            final isActive = u['is_active'];
            // Handle both bool and null cases
            return isActive == true || isActive == 1;
          })
          .toList();
      
      developer.log('📊 Total users: ${allUsersList.length}, Active: ${activeUsersList.length}', name: 'AdminService');
      
      // Count users properly
      final totalUsers = allUsersList.length;
      final studentCount = activeUsersList.where((u) {
        if (u is! Map) return false;
        return u['role'] == 'student';
      }).length;
      final securityCount = activeUsersList.where((u) {
        if (u is! Map) return false;
        return u['role'] == 'security';
      }).length;
      final adminCount = activeUsersList.where((u) {
        if (u is! Map) return false;
        return u['role'] == 'admin';
      }).length;
      
      developer.log('📊 Role breakdown - Students: $studentCount, Security: $securityCount, Admin: $adminCount', name: 'AdminService');

      // Get incidents count
      developer.log('📊 Fetching incidents...', name: 'AdminService');
      final incidentsResponse = await _supabase
          .from('incidents')
          .select('id, created_at, status, updated_at');
      
      final totalIncidents = incidentsResponse.length;

      // Get active incidents count (not resolved or closed)
      final activeIncidents = incidentsResponse
          .where((incident) {
            final status = incident['status'] as String? ?? '';
            return status != 'resolved' && status != 'closed';
          })
          .length;

      // Calculate average response time from resolved incidents
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
              if (responseTime.inMinutes > 0) {
                responseTimes.add(responseTime);
              }
            } catch (e) {
              // Skip invalid dates
              continue;
            }
          }

          if (responseTimes.isNotEmpty) {
            final avgMinutes = responseTimes
                .map((d) => d.inMinutes)
                .reduce((a, b) => a + b) / responseTimes.length;
            
            if (avgMinutes < 60) {
              avgResponseTime = '${avgMinutes.toStringAsFixed(1)}m';
            } else {
              final hours = avgMinutes / 60;
              avgResponseTime = '${hours.toStringAsFixed(1)}h';
            }
          }
        }
      } catch (e) {
        developer.log('⚠️ Error calculating response time: $e', name: 'AdminService');
      }

      developer.log('✅ KPIs fetched successfully', name: 'AdminService');

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
      developer.log('❌ Error fetching KPIs: $e', name: 'AdminService');
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

  // Get all users
  Future<List<models.User>> getAllUsers() async {
    developer.log('👥 FETCHING ALL USERS', name: 'AdminService');

    try {
      developer.log('👥 Querying users table...', name: 'AdminService');
      final response = await _supabase
          .from('users')
          .select()
          .order('created_at', ascending: false);


      final users = (response as List).map((user) {
        try {
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
        } catch (e) {
          developer.log('❌ Error parsing user: $e, User data: $user', name: 'AdminService');
          rethrow;
        }
      }).toList();

      developer.log('✅ Successfully parsed ${users.length} users', name: 'AdminService');
      return users;
    } catch (e) {
      developer.log('❌ Error fetching users: $e', name: 'AdminService');
      return [];
    }
  }

  // Update user role
  Future<bool> updateUserRole({
    required String userId,
    required String role,
  }) async {
    developer.log('🔄 UPDATING USER ROLE', name: 'AdminService');
    developer.log('👤 User ID: $userId', name: 'AdminService');
    developer.log('🎭 New Role: $role', name: 'AdminService');

    try {
      await _supabase
          .from('users')
          .update({
            'role': role,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);

      developer.log('✅ User role updated', name: 'AdminService');
      return true;
    } catch (e) {
      developer.log('❌ Error updating user role: $e', name: 'AdminService');
      return false;
    }
  }

  // Deactivate user
  Future<bool> deactivateUser(String userId) async {
    developer.log('🔕 DEACTIVATING USER', name: 'AdminService');
    developer.log('👤 User ID: $userId', name: 'AdminService');

    try {
      await _supabase
          .from('users')
          .update({
            'is_active': false,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);

      developer.log('✅ User deactivated', name: 'AdminService');
      return true;
    } catch (e) {
      developer.log('❌ Error deactivating user: $e', name: 'AdminService');
      return false;
    }
  }

  // Activate user
  Future<bool> activateUser(String userId) async {
    developer.log('✅ ACTIVATING USER', name: 'AdminService');
    developer.log('👤 User ID: $userId', name: 'AdminService');

    try {
      await _supabase
          .from('users')
          .update({
            'is_active': true,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);

      developer.log('✅ User activated', name: 'AdminService');
      return true;
    } catch (e) {
      developer.log('❌ Error activating user: $e', name: 'AdminService');
      return false;
    }
  }

  // Get incident analytics
  Future<Map<String, dynamic>> getIncidentAnalytics() async {
    developer.log('📈 FETCHING INCIDENT ANALYTICS', name: 'AdminService');

    try {
      developer.log('📈 Querying incidents for analytics...', name: 'AdminService');
      final response = await _supabase
          .from('incidents')
          .select('type, severity, created_at');

      // Group by type
      final typeBreakdown = <String, int>{};
      for (final incident in response) {
        final type = incident['type'] as String? ?? 'other';
        typeBreakdown[type] = (typeBreakdown[type] ?? 0) + 1;
      }

      // Group by severity
      final severityBreakdown = <String, int>{};
      for (final incident in response) {
        final severity = incident['severity'] as String? ?? 'medium';
        severityBreakdown[severity] = (severityBreakdown[severity] ?? 0) + 1;
      }

      // Get weekly trend (last 7 days)
      final now = DateTime.now();
      final weeklyTrend = <int>[];
      for (int i = 6; i >= 0; i--) {
        final dayStart = DateTime(now.year, now.month, now.day - i);
        final dayEnd = dayStart.add(const Duration(days: 1));
        
        final dayIncidents = response.where((incident) {
          try {
            final createdAt = DateTime.parse(incident['created_at'] as String);
            return createdAt.isAfter(dayStart) && createdAt.isBefore(dayEnd);
          } catch (e) {
            return false;
          }
        }).length;
        
        weeklyTrend.add(dayIncidents);
      }

      developer.log('✅ Analytics fetched successfully', name: 'AdminService');

      return {
        'typeBreakdown': typeBreakdown,
        'severityBreakdown': severityBreakdown,
        'weeklyTrend': weeklyTrend,
        'totalIncidents': response.length,
      };
    } catch (e) {
      developer.log('❌ Error fetching analytics: $e', name: 'AdminService');
      return {
        'typeBreakdown': {},
        'severityBreakdown': {},
        'weeklyTrend': [0, 0, 0, 0, 0, 0, 0],
        'totalIncidents': 0,
      };
    }
  }

  // Get recent activity
  Future<List<Map<String, dynamic>>> getRecentActivity({int limit = 10}) async {
    developer.log('📋 FETCHING RECENT ACTIVITY', name: 'AdminService');

    try {
      // Get recent incidents
      final incidents = await _supabase
          .from('incidents')
          .select('id, title, created_at, reported_by')
          .order('created_at', ascending: false)
          .limit(limit);

      // Get recent alerts
      final alerts = await _supabase
          .from('alerts')
          .select('id, title, created_at, created_by')
          .order('created_at', ascending: false)
          .limit(limit);

      // Get recent user registrations
      final users = await _supabase
          .from('users')
          .select('id, name, created_at')
          .order('created_at', ascending: false)
          .limit(limit);

      // Combine and sort all activities
      final activities = <Map<String, dynamic>>[];

      for (final incident in incidents) {
        activities.add({
          'type': 'incident',
          'action': 'New incident reported',
          'details': incident['title'],
          'timestamp': DateTime.parse(incident['created_at']),
          'icon': 'report',
        });
      }

      for (final alert in alerts) {
        activities.add({
          'type': 'alert',
          'action': 'Alert broadcast sent',
          'details': alert['title'],
          'timestamp': DateTime.parse(alert['created_at']),
          'icon': 'notifications',
        });
      }

      for (final user in users) {
        activities.add({
          'type': 'user',
          'action': 'User registered',
          'details': user['name'],
          'timestamp': DateTime.parse(user['created_at']),
          'icon': 'person_add',
        });
      }

      // Sort by timestamp
      activities.sort((a, b) => (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime));

      developer.log('✅ Fetched ${activities.length} activities', name: 'AdminService');

      return activities.take(limit).toList();
    } catch (e) {
      developer.log('❌ Error fetching recent activity: $e', name: 'AdminService');
      return [];
    }
  }

  // Get user statistics by role
  Future<Map<String, int>> getUserStatsByRole() async {
    developer.log('📊 FETCHING USER STATS BY ROLE', name: 'AdminService');

    try {
      final response = await _supabase
          .from('users')
          .select('role')
          .eq('is_active', true);

      final stats = <String, int>{
        'student': 0,
        'security': 0,
        'admin': 0,
      };

      for (final user in response) {
        final role = user['role'] as String;
        stats[role] = (stats[role] ?? 0) + 1;
      }

      developer.log('✅ User stats fetched: $stats', name: 'AdminService');

      return stats;
    } catch (e) {
      developer.log('❌ Error fetching user stats: $e', name: 'AdminService');
      return {'student': 0, 'security': 0, 'admin': 0};
    }
  }
}

