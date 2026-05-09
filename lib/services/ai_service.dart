import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:developer' as developer;
import '../models/incident.dart';

class AIService {
  final _supabase = Supabase.instance.client;

  // AI-Powered Incident Prioritization
  Future<List<Map<String, dynamic>>> prioritizeIncidents(List<Incident> incidents) async {
    developer.log('🤖 AI PRIORITIZING INCIDENTS', name: 'AIService');

    try {
      // Score each incident based on multiple factors
      final prioritized = incidents.map((incident) {
        double priorityScore = 0.0;

        // Severity weight (40%)
        switch (incident.severity) {
          case IncidentSeverity.critical:
            priorityScore += 40;
            break;
          case IncidentSeverity.high:
            priorityScore += 30;
            break;
          case IncidentSeverity.medium:
            priorityScore += 20;
            break;
          case IncidentSeverity.low:
            priorityScore += 10;
            break;
        }

        // Type weight (25%)
        switch (incident.type) {
          case IncidentType.assault:
          case IncidentType.fire:
          case IncidentType.medical:
            priorityScore += 25;
            break;
          case IncidentType.harassment:
            priorityScore += 20;
            break;
          case IncidentType.theft:
            priorityScore += 15;
            break;
          case IncidentType.other:
            priorityScore += 10;
            break;
        }

        // Time-based urgency (20%)
        try {
          final reportedAt = DateTime.parse(incident.reportedAt.split(' - ')[0]);
          final now = DateTime.now();
          final hoursSinceReport = now.difference(reportedAt).inHours;
          
          if (hoursSinceReport < 1) {
            priorityScore += 20; // Very recent
          } else if (hoursSinceReport < 6) {
            priorityScore += 15; // Recent
          } else if (hoursSinceReport < 24) {
            priorityScore += 10; // Today
          } else {
            priorityScore += 5; // Older
          }
        } catch (e) {
          priorityScore += 10; // Default if parsing fails
        }

        // Status weight (15%)
        switch (incident.status.toLowerCase()) {
          case 'pending':
            priorityScore += 15; // Needs immediate attention
            break;
          case 'responding':
            priorityScore += 10; // In progress
            break;
          case 'investigating':
            priorityScore += 8;
            break;
          case 'on-scene':
            priorityScore += 5;
            break;
          default:
            priorityScore += 2; // Resolved/closed
        }

        return {
          'incident': incident,
          'priorityScore': priorityScore,
          'priorityLevel': _getPriorityLevel(priorityScore),
        };
      }).toList();

      // Sort by priority score (highest first)
      prioritized.sort((a, b) => 
        (b['priorityScore'] as double).compareTo(a['priorityScore'] as double));

      developer.log('✅ Incidents prioritized: ${prioritized.length}', name: 'AIService');
      return prioritized;
    } catch (e) {
      developer.log('❌ Error prioritizing incidents: $e', name: 'AIService');
      return [];
    }
  }

  String _getPriorityLevel(double score) {
    if (score >= 80) return 'Critical';
    if (score >= 60) return 'High';
    if (score >= 40) return 'Medium';
    return 'Low';
  }

  // AI-Powered Analytics and Insights
  Future<Map<String, dynamic>> generateInsights() async {
    developer.log('🤖 GENERATING AI INSIGHTS', name: 'AIService');

    try {
      // Get recent incidents
      final incidents = await _supabase
          .from('incidents')
          .select('type, severity, location, created_at, status')
          .order('created_at', ascending: false)
          .limit(100);

      // Analyze patterns
      final insights = <String, dynamic>{
        'hotspots': _identifyHotspots(incidents),
        'trends': _identifyTrends(incidents),
        'recommendations': _generateRecommendations(incidents),
        'riskAreas': _identifyRiskAreas(incidents),
      };

      developer.log('✅ Insights generated', name: 'AIService');
      return insights;
    } catch (e) {
      developer.log('❌ Error generating insights: $e', name: 'AIService');
      return {};
    }
  }

  // Identify incident hotspots
  Map<String, dynamic> _identifyHotspots(List<dynamic> incidents) {
    final locationCounts = <String, int>{};
    
    for (final incident in incidents) {
      final location = incident['location'] as String? ?? 'Unknown';
      locationCounts[location] = (locationCounts[location] ?? 0) + 1;
    }

    final sortedLocations = locationCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return {
      'topHotspots': sortedLocations.take(5).map((e) => {
        'location': e.key,
        'incidentCount': e.value,
      }).toList(),
      'totalHotspots': locationCounts.length,
    };
  }

  // Identify trends
  Map<String, dynamic> _identifyTrends(List<dynamic> incidents) {
    // Analyze last 7 days
    final now = DateTime.now();
    final last7Days = <int>[];
    final byType = <String, int>{};

    for (int i = 6; i >= 0; i--) {
      final dayStart = DateTime(now.year, now.month, now.day - i);
      final dayEnd = dayStart.add(const Duration(days: 1));
      
      final dayCount = incidents.where((incident) {
        try {
          final createdAt = DateTime.parse(incident['created_at'] as String);
          return createdAt.isAfter(dayStart) && createdAt.isBefore(dayEnd);
        } catch (e) {
          return false;
        }
      }).length;
      
      last7Days.add(dayCount);
    }

    // Count by type
    for (final incident in incidents) {
      final type = incident['type'] as String? ?? 'other';
      byType[type] = (byType[type] ?? 0) + 1;
    }

    // Determine trend
    final recentAvg = last7Days.take(3).reduce((a, b) => a + b) / 3;
    final olderAvg = last7Days.skip(3).reduce((a, b) => a + b) / 3;
    final trend = recentAvg > olderAvg ? 'increasing' : recentAvg < olderAvg ? 'decreasing' : 'stable';

    return {
      'dailyCounts': last7Days,
      'trend': trend,
      'trendPercentage': olderAvg > 0
          ? (((recentAvg - olderAvg) / olderAvg) * 100).toStringAsFixed(1)
          : '0.0',
      'mostCommonType': byType.entries.isNotEmpty
          ? byType.entries.reduce((a, b) => a.value > b.value ? a : b).key
          : 'none',
    };
  }

  // Generate AI recommendations
  List<Map<String, dynamic>> _generateRecommendations(List<dynamic> incidents) {
    final recommendations = <Map<String, dynamic>>[];

    // Analyze pending incidents
    final pendingIncidents = incidents.where((i) => 
      i['status'] == 'pending').length;
    
    if (pendingIncidents > 5) {
      recommendations.add({
        'type': 'urgent',
        'title': 'High Pending Incidents',
        'message': 'You have $pendingIncidents pending incidents. Consider assigning more officers.',
        'action': 'assign_officers',
      });
    }

    // Analyze response times
    final recentResolved = incidents.where((i) {
      if (i['status'] != 'resolved' && i['status'] != 'closed') return false;
      try {
        final createdAt = DateTime.parse(i['created_at'] as String);
        return DateTime.now().difference(createdAt).inDays < 7;
      } catch (e) {
        return false;
      }
    }).toList();

    if (recentResolved.isNotEmpty) {
      double totalTime = 0;
      int count = 0;
      for (final incident in recentResolved) {
        try {
          final createdAt = DateTime.parse(incident['created_at'] as String);
          final updatedAt = incident['updated_at'] != null
              ? DateTime.parse(incident['updated_at'] as String)
              : createdAt;
          final time = updatedAt.difference(createdAt).inMinutes;
          if (time > 0) {
            totalTime += time;
            count++;
          }
        } catch (e) {
          // Skip
        }
      }

      if (count > 0) {
        final avgTime = totalTime / count;
        if (avgTime > 30) {
          recommendations.add({
            'type': 'warning',
            'title': 'Slow Response Times',
            'message': 'Average response time is ${avgTime.toStringAsFixed(1)} minutes. Target is under 15 minutes.',
            'action': 'review_process',
          });
        }
      }
    }

    // Analyze hotspots
    final locationCounts = <String, int>{};
    for (final incident in incidents) {
      final location = incident['location'] as String? ?? 'Unknown';
      locationCounts[location] = (locationCounts[location] ?? 0) + 1;
    }

    if (locationCounts.isNotEmpty) {
      final topHotspot = locationCounts.entries.reduce((a, b) => a.value > b.value ? a : b);
      if (topHotspot.value >= 3) {
        recommendations.add({
          'type': 'info',
          'title': 'Incident Hotspot Detected',
          'message': '${topHotspot.key} has ${topHotspot.value} incidents. Consider increased patrols.',
          'action': 'increase_patrols',
        });
      }
    }

    return recommendations;
  }

  // Identify risk areas
  Map<String, dynamic> _identifyRiskAreas(List<dynamic> incidents) {
    final riskScores = <String, double>{};
    
    for (final incident in incidents) {
      final location = incident['location'] as String? ?? 'Unknown';
      final severity = incident['severity'] as String? ?? 'medium';
      
      double severityScore = 0;
      switch (severity) {
        case 'critical':
          severityScore = 4;
          break;
        case 'high':
          severityScore = 3;
          break;
        case 'medium':
          severityScore = 2;
          break;
        case 'low':
          severityScore = 1;
          break;
      }

      riskScores[location] = (riskScores[location] ?? 0) + severityScore;
    }

    final sortedRisks = riskScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return {
      'highRiskAreas': sortedRisks.take(5).map((e) => {
        'location': e.key,
        'riskScore': e.value.toStringAsFixed(1),
      }).toList(),
    };
  }

  // Predict incident likelihood (simple ML-like approach)
  Future<Map<String, dynamic>> predictIncidentLikelihood(String location) async {
    developer.log('🤖 PREDICTING INCIDENT LIKELIHOOD', name: 'AIService');

    try {
      // Get historical incidents at this location
      final historical = await _supabase
          .from('incidents')
          .select('created_at, type, severity')
          .eq('location', location)
          .order('created_at', ascending: false)
          .limit(50);

      if (historical.isEmpty) {
        return {
          'location': location,
          'likelihood': 'low',
          'confidence': 'low',
          'reason': 'No historical data available',
        };
      }

      // Analyze patterns
      final recentCount = historical.where((incident) {
        try {
          final createdAt = DateTime.parse(incident['created_at'] as String);
          return DateTime.now().difference(createdAt).inDays < 30;
        } catch (e) {
          return false;
        }
      }).length;

      String likelihood;
      String confidence;
      String reason;

      if (recentCount >= 5) {
        likelihood = 'high';
        confidence = 'high';
        reason = 'High frequency of recent incidents at this location';
      } else if (recentCount >= 2) {
        likelihood = 'medium';
        confidence = 'medium';
        reason = 'Moderate incident frequency observed';
      } else {
        likelihood = 'low';
        confidence = 'low';
        reason = 'Low historical incident rate';
      }

      return {
        'location': location,
        'likelihood': likelihood,
        'confidence': confidence,
        'reason': reason,
        'recentIncidents': recentCount,
      };
    } catch (e) {
      developer.log('❌ Error predicting likelihood: $e', name: 'AIService');
      return {
        'location': location,
        'likelihood': 'unknown',
        'confidence': 'low',
        'reason': 'Error analyzing data',
      };
    }
  }
}

