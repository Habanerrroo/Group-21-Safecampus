import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:developer' as developer;

class ReportService {
  final _supabase = Supabase.instance.client;

  // Generate Incident Summary Report
  Future<Map<String, dynamic>> generateIncidentSummaryReport({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    developer.log('📄 GENERATING INCIDENT SUMMARY REPORT', name: 'ReportService');

    try {
      var query = _supabase.from('incidents').select();

      if (startDate != null) {
        query = query.gte('created_at', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('created_at', endDate.toIso8601String());
      }

      final incidents = await query.order('created_at', ascending: false);

      // Calculate statistics
      final totalIncidents = incidents.length;
      final byType = <String, int>{};
      final bySeverity = <String, int>{};
      final byStatus = <String, int>{};
      int resolvedCount = 0;
      double totalResponseTime = 0;
      int resolvedWithTime = 0;

      for (final incident in incidents) {
        // By type
        final type = incident['type'] as String? ?? 'other';
        byType[type] = (byType[type] ?? 0) + 1;

        // By severity
        final severity = incident['severity'] as String? ?? 'medium';
        bySeverity[severity] = (bySeverity[severity] ?? 0) + 1;

        // By status
        final status = incident['status'] as String? ?? 'pending';
        byStatus[status] = (byStatus[status] ?? 0) + 1;

        // Response time for resolved incidents
        if (status == 'resolved' || status == 'closed') {
          resolvedCount++;
          try {
            final createdAt = DateTime.parse(incident['created_at'] as String);
            final updatedAt = incident['updated_at'] != null
                ? DateTime.parse(incident['updated_at'] as String)
                : createdAt;
            final responseTime = updatedAt.difference(createdAt).inMinutes;
            if (responseTime > 0) {
              totalResponseTime += responseTime;
              resolvedWithTime++;
            }
          } catch (e) {
            // Skip invalid dates
          }
        }
      }

      final avgResponseTime = resolvedWithTime > 0
          ? (totalResponseTime / resolvedWithTime).toStringAsFixed(1)
          : 'N/A';

      developer.log('✅ Report generated successfully', name: 'ReportService');

      return {
        'reportType': 'incident_summary',
        'period': {
          'start': startDate?.toIso8601String(),
          'end': endDate?.toIso8601String(),
        },
        'summary': {
          'totalIncidents': totalIncidents,
          'resolvedCount': resolvedCount,
          'resolutionRate': totalIncidents > 0
              ? ((resolvedCount / totalIncidents) * 100).toStringAsFixed(1)
              : '0.0',
          'avgResponseTime': avgResponseTime,
        },
        'breakdown': {
          'byType': byType,
          'bySeverity': bySeverity,
          'byStatus': byStatus,
        },
        'incidents': incidents,
        'generatedAt': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      developer.log('❌ Error generating report: $e', name: 'ReportService');
      rethrow;
    }
  }

  // Generate User Activity Report
  Future<Map<String, dynamic>> generateUserActivityReport({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    developer.log('📄 GENERATING USER ACTIVITY REPORT', name: 'ReportService');

    try {
      // Get users
      final users = await _supabase
          .from('users')
          .select('id, name, email, role, created_at, is_active')
          .order('created_at', ascending: false);

      // Get incidents reported by users
      var incidentQuery = _supabase
          .from('incidents')
          .select('id, reported_by, created_at');

      if (startDate != null) {
        incidentQuery = incidentQuery.gte('created_at', startDate.toIso8601String());
      }
      if (endDate != null) {
        incidentQuery = incidentQuery.lte('created_at', endDate.toIso8601String());
      }

      final incidents = await incidentQuery;

      // Calculate user activity
      final userActivity = <String, Map<String, dynamic>>{};
      for (final user in users) {
        final userId = user['id'] as String;
        final userIncidents = incidents.where((i) => i['reported_by'] == userId).length;

        userActivity[userId] = {
          'name': user['name'],
          'email': user['email'],
          'role': user['role'],
          'incidentsReported': userIncidents,
          'isActive': user['is_active'] ?? true,
          'joinedAt': user['created_at'],
        };
      }

      // Calculate totals
      final totalUsers = users.length;
      final activeUsers = users.where((u) => u['is_active'] == true).length;
      final totalReports = incidents.length;
      final avgReportsPerUser = totalUsers > 0 ? (totalReports / totalUsers).toStringAsFixed(1) : '0.0';

      developer.log('✅ User activity report generated', name: 'ReportService');

      return {
        'reportType': 'user_activity',
        'period': {
          'start': startDate?.toIso8601String(),
          'end': endDate?.toIso8601String(),
        },
        'summary': {
          'totalUsers': totalUsers,
          'activeUsers': activeUsers,
          'totalReports': totalReports,
          'avgReportsPerUser': avgReportsPerUser,
        },
        'userActivity': userActivity,
        'generatedAt': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      developer.log('❌ Error generating user activity report: $e', name: 'ReportService');
      rethrow;
    }
  }

  // Generate Response Time Analysis Report
  Future<Map<String, dynamic>> generateResponseTimeReport({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    developer.log('📄 GENERATING RESPONSE TIME REPORT', name: 'ReportService');

    try {
      var query = _supabase
          .from('incidents')
          .select('id, created_at, updated_at, status, severity, type');

      if (startDate != null) {
        query = query.gte('created_at', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('created_at', endDate.toIso8601String());
      }

      final allIncidents = await query.order('created_at', ascending: false);

      // Filter resolved/closed incidents
      final incidents = allIncidents.where((incident) {
        final status = incident['status'] as String? ?? '';
        return status == 'resolved' || status == 'closed';
      }).toList();

      final responseTimes = <int>[];
      final bySeverity = <String, List<int>>{};
      final byType = <String, List<int>>{};

      for (final incident in incidents) {
        try {
          final createdAt = DateTime.parse(incident['created_at'] as String);
          final updatedAt = incident['updated_at'] != null
              ? DateTime.parse(incident['updated_at'] as String)
              : createdAt;
          final responseTime = updatedAt.difference(createdAt).inMinutes;

          if (responseTime > 0) {
            responseTimes.add(responseTime);

            final severity = incident['severity'] as String? ?? 'medium';
            bySeverity.putIfAbsent(severity, () => []).add(responseTime);

            final type = incident['type'] as String? ?? 'other';
            byType.putIfAbsent(type, () => []).add(responseTime);
          }
        } catch (e) {
          // Skip invalid dates
        }
      }

      // Calculate statistics
      final avgResponseTime = responseTimes.isNotEmpty
          ? (responseTimes.reduce((a, b) => a + b) / responseTimes.length).toStringAsFixed(1)
          : 'N/A';

      final minResponseTime = responseTimes.isNotEmpty
          ? responseTimes.reduce((a, b) => a < b ? a : b)
          : 0;
      final maxResponseTime = responseTimes.isNotEmpty
          ? responseTimes.reduce((a, b) => a > b ? a : b)
          : 0;

      // Calculate averages by severity and type
      final avgBySeverity = <String, String>{};
      bySeverity.forEach((severity, times) {
        if (times.isNotEmpty) {
          avgBySeverity[severity] = (times.reduce((a, b) => a + b) / times.length).toStringAsFixed(1);
        }
      });

      final avgByType = <String, String>{};
      byType.forEach((type, times) {
        if (times.isNotEmpty) {
          avgByType[type] = (times.reduce((a, b) => a + b) / times.length).toStringAsFixed(1);
        }
      });

      developer.log('✅ Response time report generated', name: 'ReportService');

      return {
        'reportType': 'response_time',
        'period': {
          'start': startDate?.toIso8601String(),
          'end': endDate?.toIso8601String(),
        },
        'summary': {
          'totalResolved': incidents.length,
          'avgResponseTime': avgResponseTime,
          'minResponseTime': minResponseTime,
          'maxResponseTime': maxResponseTime,
        },
        'breakdown': {
          'bySeverity': avgBySeverity,
          'byType': avgByType,
        },
        'generatedAt': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      developer.log('❌ Error generating response time report: $e', name: 'ReportService');
      rethrow;
    }
  }

  // Generate Security Staff Performance Report
  Future<Map<String, dynamic>> generateStaffPerformanceReport({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    developer.log('📄 GENERATING STAFF PERFORMANCE REPORT', name: 'ReportService');

    try {
      // Get security staff
      final staff = await _supabase
          .from('users')
          .select('id, name, email, student_id')
          .eq('role', 'security')
          .eq('is_active', true);

      // Get incidents assigned to staff
      var incidentQuery = _supabase
          .from('incidents')
          .select('id, assigned_officer, status, created_at, updated_at');

      if (startDate != null) {
        incidentQuery = incidentQuery.gte('created_at', startDate.toIso8601String());
      }
      if (endDate != null) {
        incidentQuery = incidentQuery.lte('created_at', endDate.toIso8601String());
      }

      final incidents = await incidentQuery;

      // Calculate performance for each staff member
      final staffPerformance = <String, Map<String, dynamic>>{};
      for (final officer in staff) {
        final officerId = officer['id'] as String;
        final officerIncidents = incidents.where((i) => i['assigned_officer'] == officerId).toList();
        final resolvedIncidents = officerIncidents.where((i) =>
            i['status'] == 'resolved' || i['status'] == 'closed').length;

        // Calculate average response time
        double totalResponseTime = 0;
        int resolvedWithTime = 0;
        for (final incident in officerIncidents) {
          if (incident['status'] == 'resolved' || incident['status'] == 'closed') {
            try {
              final createdAt = DateTime.parse(incident['created_at'] as String);
              final updatedAt = incident['updated_at'] != null
                  ? DateTime.parse(incident['updated_at'] as String)
                  : createdAt;
              final responseTime = updatedAt.difference(createdAt).inMinutes;
              if (responseTime > 0) {
                totalResponseTime += responseTime;
                resolvedWithTime++;
              }
            } catch (e) {
              // Skip invalid dates
            }
          }
        }

        final avgResponseTime = resolvedWithTime > 0
            ? (totalResponseTime / resolvedWithTime).toStringAsFixed(1)
            : 'N/A';

        staffPerformance[officerId] = {
          'name': officer['name'],
          'badge': officer['student_id'],
          'totalAssigned': officerIncidents.length,
          'resolved': resolvedIncidents,
          'resolutionRate': officerIncidents.isNotEmpty
              ? ((resolvedIncidents / officerIncidents.length) * 100).toStringAsFixed(1)
              : '0.0',
          'avgResponseTime': avgResponseTime,
        };
      }

      developer.log('✅ Staff performance report generated', name: 'ReportService');

      return {
        'reportType': 'staff_performance',
        'period': {
          'start': startDate?.toIso8601String(),
          'end': endDate?.toIso8601String(),
        },
        'summary': {
          'totalStaff': staff.length,
        },
        'staffPerformance': staffPerformance,
        'generatedAt': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      developer.log('❌ Error generating staff performance report: $e', name: 'ReportService');
      rethrow;
    }
  }
}

