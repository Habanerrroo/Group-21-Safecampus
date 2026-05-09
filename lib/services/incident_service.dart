import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:developer' as developer;
import '../models/incident.dart';
import 'storage_service_upload.dart';

class IncidentService {
  final _supabase = Supabase.instance.client;
  final _storageService = StorageServiceUpload();

  // Create a new incident
  Future<String?> createIncident({
    required String title,
    required String type,
    required String severity,
    required String location,
    required String description,
    double? latitude,
    double? longitude,
    bool isAnonymous = false,
  }) async {
    developer.log('📝 CREATING INCIDENT', name: 'IncidentService');
    developer.log('📋 Title: $title', name: 'IncidentService');
    developer.log('🏷️ Type: $type', name: 'IncidentService');
    developer.log('⚠️ Severity: $severity', name: 'IncidentService');

    try {
      final currentUser = _supabase.auth.currentUser;
      
      final incidentData = {
        'title': title,
        'type': type,
        'severity': severity,
        'status': 'pending',
        'location': location,
        'description': description,
        'latitude': latitude,
        'longitude': longitude,
        'is_anonymous': isAnonymous,
        'reported_by': isAnonymous ? null : currentUser?.id,
        'created_at': DateTime.now().toIso8601String(),
      };

      developer.log('📋 Incident data: $incidentData', name: 'IncidentService');

      final response = await _supabase
          .from('incidents')
          .insert(incidentData)
          .select('id')
          .single();

      final incidentId = response['id'];
      developer.log('✅ Incident created with ID: $incidentId', name: 'IncidentService');

      return incidentId;
    } catch (e) {
      developer.log('❌ Error creating incident: $e', name: 'IncidentService');
      return null;
    }
  }

  // Upload incident media
  Future<bool> uploadIncidentMedia({
    required String incidentId,
    required String mediaType,
    required String filePath,
  }) async {
    developer.log('📤 UPLOADING INCIDENT MEDIA', name: 'IncidentService');
    developer.log('🆔 Incident ID: $incidentId', name: 'IncidentService');
    developer.log('📁 Media Type: $mediaType', name: 'IncidentService');

    try {
      final currentUser = _supabase.auth.currentUser;
      
      // Upload to Supabase Storage
      String? mediaUrl;
      if (mediaType == 'photo') {
        mediaUrl = await _storageService.uploadIncidentPhoto(
          incidentId: incidentId,
          filePath: filePath,
        );
      } else {
        // For other media types, use generic upload
        mediaUrl = await _storageService.uploadFile(
          bucket: 'incident-media',
          filePath: filePath,
          fileName: 'incidents/$incidentId/${DateTime.now().millisecondsSinceEpoch}',
        );
      }

      if (mediaUrl == null) {
        developer.log('❌ Failed to upload to storage', name: 'IncidentService');
        return false;
      }

      // Store the public URL in database
      await _supabase.from('incident_media').insert({
        'incident_id': incidentId,
        'media_type': mediaType,
        'media_url': mediaUrl,
        'uploaded_by': currentUser?.id,
        'created_at': DateTime.now().toIso8601String(),
      });

      developer.log('✅ Media uploaded successfully', name: 'IncidentService');
      return true;
    } catch (e) {
      developer.log('❌ Error uploading media: $e', name: 'IncidentService');
      return false;
    }
  }

  // Get user's incidents
  Future<List<Incident>> getUserIncidents(String userId) async {
    developer.log('📋 FETCHING USER INCIDENTS', name: 'IncidentService');
    developer.log('👤 User ID: $userId', name: 'IncidentService');

    try {
      final response = await _supabase
          .from('incidents')
          .select()
          .eq('reported_by', userId)
          .order('created_at', ascending: false);

      developer.log('✅ Fetched ${response.length} incidents', name: 'IncidentService');

      return (response as List).map((incident) {
        return Incident(
          id: incident['id'],
          title: incident['title'],
          type: _parseIncidentType(incident['type']),
          severity: _parseIncidentSeverity(incident['severity']),
          status: incident['status'],
          location: incident['location'],
          reportedAt: _formatTimestamp(incident['created_at']),
          reportedBy: incident['is_anonymous'] ? 'Anonymous' : 'You',
          description: incident['description'],
          x: incident['latitude']?.toDouble(),
          y: incident['longitude']?.toDouble(),
        );
      }).toList();
    } catch (e) {
      developer.log('❌ Error fetching incidents: $e', name: 'IncidentService');
      return [];
    }
  }

  // Get all incidents (for security/admin)
  Future<List<Incident>> getAllIncidents() async {
    developer.log('📋 FETCHING ALL INCIDENTS', name: 'IncidentService');

    try {
      final response = await _supabase
          .from('incidents')
          .select()
          .order('created_at', ascending: false)
          .limit(50);

      developer.log('✅ Fetched ${response.length} incidents', name: 'IncidentService');

      return (response as List).map((incident) {
        return Incident(
          id: incident['id'],
          title: incident['title'],
          type: _parseIncidentType(incident['type']),
          severity: _parseIncidentSeverity(incident['severity']),
          status: incident['status'],
          location: incident['location'],
          reportedAt: _formatTimestamp(incident['created_at']),
          reportedBy: incident['is_anonymous'] ? 'Anonymous' : 'Student',
          description: incident['description'],
          assignedOfficer: incident['assigned_officer'],
          notes: incident['notes'],
          x: incident['latitude']?.toDouble(),
          y: incident['longitude']?.toDouble(),
        );
      }).toList();
    } catch (e) {
      developer.log('❌ Error fetching all incidents: $e', name: 'IncidentService');
      return [];
    }
  }

  // Get active incidents (not resolved or closed)
  Future<List<Incident>> getActiveIncidents() async {
    developer.log('📋 FETCHING ACTIVE INCIDENTS', name: 'IncidentService');

    try {
      final response = await _supabase
          .from('incidents')
          .select()
          .not('status', 'in', '(resolved,closed)')
          .order('created_at', ascending: false);

      developer.log('✅ Fetched ${response.length} active incidents', name: 'IncidentService');

      return (response as List).map((incident) {
        return Incident(
          id: incident['id'],
          title: incident['title'],
          type: _parseIncidentType(incident['type']),
          severity: _parseIncidentSeverity(incident['severity']),
          status: incident['status'],
          location: incident['location'],
          reportedAt: _formatTimestamp(incident['created_at']),
          reportedBy: incident['is_anonymous'] ? 'Anonymous' : 'Student',
          description: incident['description'],
          assignedOfficer: incident['assigned_officer'],
          notes: incident['notes'],
          x: incident['latitude']?.toDouble(),
          y: incident['longitude']?.toDouble(),
        );
      }).toList();
    } catch (e) {
      developer.log('❌ Error fetching active incidents: $e', name: 'IncidentService');
      return [];
    }
  }

  // Get incidents assigned to specific officer
  Future<List<Incident>> getOfficerIncidents(String officerId) async {
    developer.log('📋 FETCHING OFFICER INCIDENTS', name: 'IncidentService');
    developer.log('👮 Officer ID: $officerId', name: 'IncidentService');

    try {
      final response = await _supabase
          .from('incidents')
          .select()
          .eq('assigned_officer', officerId)
          .not('status', 'in', '(resolved,closed)')
          .order('created_at', ascending: false);

      developer.log('✅ Fetched ${response.length} officer incidents', name: 'IncidentService');

      return (response as List).map((incident) {
        return Incident(
          id: incident['id'],
          title: incident['title'],
          type: _parseIncidentType(incident['type']),
          severity: _parseIncidentSeverity(incident['severity']),
          status: incident['status'],
          location: incident['location'],
          reportedAt: _formatTimestamp(incident['created_at']),
          reportedBy: incident['is_anonymous'] ? 'Anonymous' : 'Student',
          description: incident['description'],
          assignedOfficer: incident['assigned_officer'],
          notes: incident['notes'],
          x: incident['latitude']?.toDouble(),
          y: incident['longitude']?.toDouble(),
        );
      }).toList();
    } catch (e) {
      developer.log('❌ Error fetching officer incidents: $e', name: 'IncidentService');
      return [];
    }
  }

  // Update incident status
  Future<bool> updateIncidentStatus({
    required String incidentId,
    required String status,
    String? notes,
  }) async {
    developer.log('🔄 UPDATING INCIDENT STATUS', name: 'IncidentService');
    developer.log('🆔 Incident ID: $incidentId', name: 'IncidentService');
    developer.log('📊 New Status: $status', name: 'IncidentService');

    try {
      final updates = <String, dynamic>{
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (notes != null) {
        updates['notes'] = notes;
      }

      await _supabase
          .from('incidents')
          .update(updates)
          .eq('id', incidentId);

      developer.log('✅ Incident status updated', name: 'IncidentService');
      return true;
    } catch (e) {
      developer.log('❌ Error updating incident status: $e', name: 'IncidentService');
      return false;
    }
  }

  // Assign incident to officer
  Future<bool> assignIncident({
    required String incidentId,
    required String officerId,
  }) async {
    developer.log('👮 ASSIGNING INCIDENT', name: 'IncidentService');
    developer.log('🆔 Incident ID: $incidentId', name: 'IncidentService');
    developer.log('👮 Officer ID: $officerId', name: 'IncidentService');

    try {
      await _supabase
          .from('incidents')
          .update({
            'assigned_officer': officerId,
            'status': 'responding',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', incidentId);

      developer.log('✅ Incident assigned', name: 'IncidentService');
      return true;
    } catch (e) {
      developer.log('❌ Error assigning incident: $e', name: 'IncidentService');
      return false;
    }
  }

  // Subscribe to incident changes
  Stream<List<Incident>> subscribeToIncidents() {
    developer.log('🔔 SUBSCRIBING TO INCIDENTS', name: 'IncidentService');

    return _supabase
        .from('incidents')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) {
          developer.log('🔔 Received ${data.length} incidents from stream', name: 'IncidentService');
          return data.map((incident) {
            return Incident(
              id: incident['id'],
              title: incident['title'],
              type: _parseIncidentType(incident['type']),
              severity: _parseIncidentSeverity(incident['severity']),
              status: incident['status'],
              location: incident['location'],
              reportedAt: _formatTimestamp(incident['created_at']),
              reportedBy: incident['is_anonymous'] ? 'Anonymous' : 'Student',
              description: incident['description'],
              assignedOfficer: incident['assigned_officer'],
              notes: incident['notes'],
              x: incident['latitude']?.toDouble(),
              y: incident['longitude']?.toDouble(),
            );
          }).toList();
        });
  }

  // Get incident count by status
  Future<Map<String, int>> getIncidentStats() async {
    developer.log('📊 FETCHING INCIDENT STATS', name: 'IncidentService');

    try {
      final response = await _supabase
          .from('incidents')
          .select('status');

      final stats = <String, int>{
        'total': response.length,
        'pending': 0,
        'responding': 0,
        'investigating': 0,
        'on-scene': 0,
        'resolved': 0,
        'closed': 0,
      };

      for (final incident in response) {
        final status = incident['status'] as String;
        stats[status] = (stats[status] ?? 0) + 1;
      }

      developer.log('✅ Stats: $stats', name: 'IncidentService');
      return stats;
    } catch (e) {
      developer.log('❌ Error fetching stats: $e', name: 'IncidentService');
      return {'total': 0};
    }
  }

  // Helper methods
  IncidentType _parseIncidentType(String type) {
    switch (type.toLowerCase()) {
      case 'theft':
        return IncidentType.theft;
      case 'assault':
        return IncidentType.assault;
      case 'harassment':
        return IncidentType.harassment;
      case 'fire':
        return IncidentType.fire;
      case 'medical':
        return IncidentType.medical;
      default:
        return IncidentType.other;
    }
  }

  IncidentSeverity _parseIncidentSeverity(String severity) {
    switch (severity.toLowerCase()) {
      case 'low':
        return IncidentSeverity.low;
      case 'medium':
        return IncidentSeverity.medium;
      case 'high':
        return IncidentSeverity.high;
      case 'critical':
        return IncidentSeverity.critical;
      default:
        return IncidentSeverity.medium;
    }
  }

  String _formatTimestamp(String timestamp) {
    try {
      final date = DateTime.parse(timestamp);
      final now = DateTime.now();
      
      if (date.year == now.year && date.month == now.month && date.day == now.day) {
        return '${date.hour}:${date.minute.toString().padLeft(2, '0')} - Today';
      } else {
        return '${date.month}/${date.day}/${date.year}';
      }
    } catch (e) {
      return timestamp;
    }
  }
}

