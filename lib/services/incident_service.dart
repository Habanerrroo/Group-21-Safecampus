import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/incident.dart';
import 'storage_service_upload.dart';
import 'notification_service.dart';

class IncidentService {
  final _supabase = Supabase.instance.client;
  final _storageService = StorageServiceUpload();
  final _notificationService = NotificationService();

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


      final response = await _supabase
          .from('incidents')
          .insert(incidentData)
          .select('id')
          .single();

      final incidentId = response['id'];

      // Send notifications to security officers (non-blocking)
      _sendIncidentNotifications(
        incidentId: incidentId,
        title: title,
        type: type,
        severity: severity,
        location: location,
        description: description,
      );

      return incidentId;
    } catch (e) {
      return null;
    }
  }

  // Upload incident media
  Future<bool> uploadIncidentMedia({
    required String incidentId,
    required String mediaType,
    required String filePath,
  }) async {

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

      return true;
    } catch (e) {
      return false;
    }
  }

  // Get user's incidents
  Future<List<Incident>> getUserIncidents(String userId) async {

    try {
      final response = await _supabase
          .from('incidents')
          .select()
          .eq('reported_by', userId)
          .order('created_at', ascending: false);


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
      return [];
    }
  }

  // Get all incidents (for security/admin)
  Future<List<Incident>> getAllIncidents() async {

    try {
      final response = await _supabase
          .from('incidents')
          .select()
          .order('created_at', ascending: false)
          .limit(50);


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
      return [];
    }
  }

  // Get active incidents (not resolved or closed)
  Future<List<Incident>> getActiveIncidents() async {

    try {
      final response = await _supabase
          .from('incidents')
          .select()
          .not('status', 'in', '(resolved,closed)')
          .order('created_at', ascending: false);


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
      return [];
    }
  }

  // Get incidents assigned to specific officer
  Future<List<Incident>> getOfficerIncidents(String officerId) async {

    try {
      final response = await _supabase
          .from('incidents')
          .select()
          .eq('assigned_officer', officerId)
          .not('status', 'in', '(resolved,closed)')
          .order('created_at', ascending: false);


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
      return [];
    }
  }

  // Update incident status
  Future<bool> updateIncidentStatus({
    required String incidentId,
    required String status,
    String? notes,
  }) async {

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


      // Send update notification (non-blocking)
      _sendUpdateNotification(incidentId: incidentId, status: status, notes: notes);

      return true;
    } catch (e) {
      return false;
    }
  }

  // Assign incident to officer
  Future<bool> assignIncident({
    required String incidentId,
    required String officerId,
  }) async {

    try {
      await _supabase
          .from('incidents')
          .update({
        'assigned_officer': officerId,
        'status': 'responding',
        'updated_at': DateTime.now().toIso8601String(),
      })
          .eq('id', incidentId);

      return true;
    } catch (e) {
      return false;
    }
  }

  // Subscribe to incident changes
  Stream<List<Incident>> subscribeToIncidents() {

    return _supabase
        .from('incidents')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) {
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

      return stats;
    } catch (e) {
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

  // Get security officer emails for notifications
  Future<List<String>> _getSecurityOfficerEmails() async {
    try {
      final response = await _supabase
          .from('users')
          .select('email')
          .eq('role', 'security')
          .eq('is_active', true);

      final emails = (response as List)
          .map((user) => user['email'] as String?)
          .whereType<String>()
          .toList();

      return emails;
    } catch (e) {
      return [];
    }
  }

  // Send incident notifications to security officers
  Future<void> _sendIncidentNotifications({
    required String incidentId,
    required String title,
    required String type,
    required String severity,
    required String location,
    required String description,
  }) async {
    try {
      final emails = await _getSecurityOfficerEmails();
      if (emails.isEmpty) {
        return;
      }

      // Send to all security officers
      for (final email in emails) {
        _notificationService.sendIncidentNotification(
          to: email,
          incidentTitle: title,
          incidentType: type,
          incidentSeverity: severity,
          incidentLocation: location,
          incidentDescription: description,
          incidentId: incidentId,
        ).catchError((e) {
          return false;
        });
      }
    } catch (e) {
    }
  }

  // Send update notification
  Future<void> _sendUpdateNotification({
    required String incidentId,
    required String status,
    String? notes,
  }) async {
    try {
      // Get incident details
      final incidentResponse = await _supabase
          .from('incidents')
          .select('title, reported_by')
          .eq('id', incidentId)
          .single();

      final title = incidentResponse['title'] as String? ?? 'Incident';
      final reportedBy = incidentResponse['reported_by'] as String?;

      // Send to reporter if available
      if (reportedBy != null) {
        final userResponse = await _supabase
            .from('users')
            .select('email')
            .eq('id', reportedBy)
            .single();

        final email = userResponse['email'] as String?;
        if (email != null) {
          _notificationService.sendIncidentUpdateNotification(
            to: email,
            incidentTitle: title,
            status: status,
            notes: notes,
          ).catchError((e) {
            return false;
          });
        }
      }
    } catch (e) {
    }
  }
}