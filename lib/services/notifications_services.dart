import 'package:http/http.dart' as http;
import 'dart:convert';

class NotificationService {
  static const String _resendApiKey = String.fromEnvironment(
    'RESEND_API_KEY',
    defaultValue: 're_X9Z1kvrw_2ND5bLdst2DQ212ixniuMoZZ',
  );

  static const String _resendApiUrl = 'https://api.resend.com/emails';
  static const String _defaultFromEmail = 'onboarding@resend.dev';

  Future<bool> sendEmail({
    required String to,
    required String subject,
    required String html,
    String? text,
    String? from,
  }) async {
    if (_resendApiKey.isEmpty) return false;

    try {
      final response = await http.post(
        Uri.parse(_resendApiUrl),
        headers: {
          'Authorization': 'Bearer $_resendApiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'from': from ?? _defaultFromEmail,
          'to': [to],
          'subject': subject,
          'html': html,
          if (text != null) 'text': text,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Send incident notification email to security officers
  Future<bool> sendIncidentNotification({
    required String to,
    required String incidentTitle,
    required String incidentType,
    required String incidentSeverity,
    required String incidentLocation,
    required String incidentDescription,
    String? incidentId,
  }) async {
    final html = _buildIncidentEmailTemplate(
      incidentTitle: incidentTitle,
      incidentType: incidentType,
      incidentSeverity: incidentSeverity,
      incidentLocation: incidentLocation,
      incidentDescription: incidentDescription,
      incidentId: incidentId,
    );

    return sendEmail(
      to: to,
      subject: '🚨 New Incident: $incidentTitle',
      html: html,
      text: _buildIncidentEmailText(
        incidentTitle: incidentTitle,
        incidentType: incidentType,
        incidentSeverity: incidentSeverity,
        incidentLocation: incidentLocation,
        incidentDescription: incidentDescription,
      ),
    );
  }

  /// Send SOS emergency notification
  Future<bool> sendSOSNotification({
    required String to,
    required String studentName,
    required String location,
    String? latitude,
    String? longitude,
  }) async {
    final html = _buildSOSEmailTemplate(
      studentName: studentName,
      location: location,
      latitude: latitude,
      longitude: longitude,
    );

    return sendEmail(
      to: to,
      subject: '🚨 EMERGENCY SOS: $studentName',
      html: html,
      text: _buildSOSEmailText(
        studentName: studentName,
        location: location,
      ),
    );
  }

  /// Send incident status update notification
  Future<bool> sendIncidentUpdateNotification({
    required String to,
    required String incidentTitle,
    required String status,
    String? notes,
  }) async {
    final html = _buildUpdateEmailTemplate(
      incidentTitle: incidentTitle,
      status: status,
      notes: notes,
    );

    return sendEmail(
      to: to,
      subject: '📋 Incident Update: $incidentTitle',
      html: html,
    );
  }

  // Email template builders
  String _buildIncidentEmailTemplate({
    required String incidentTitle,
    required String incidentType,
    required String incidentSeverity,
    required String incidentLocation,
    required String incidentDescription,
    String? incidentId,
  }) {
    final severityColor = _getSeverityColor(incidentSeverity);

    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <style>
    body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
    .container { max-width: 600px; margin: 0 auto; padding: 20px; }
    .header { background-color: $severityColor; color: white; padding: 20px; border-radius: 8px 8px 0 0; }
    .content { background-color: #f9f9f9; padding: 20px; border-radius: 0 0 8px 8px; }
    .detail-row { margin: 10px 0; }
    .label { font-weight: bold; color: #666; }
    .value { color: #333; }
    .button { display: inline-block; padding: 12px 24px; background-color: $severityColor; color: white; text-decoration: none; border-radius: 4px; margin-top: 20px; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>🚨 New Incident Reported</h1>
    </div>
    <div class="content">
      <h2>$incidentTitle</h2>
      <div class="detail-row">
        <span class="label">Type:</span> <span class="value">$incidentType</span>
      </div>
      <div class="detail-row">
        <span class="label">Severity:</span> <span class="value">$incidentSeverity</span>
      </div>
      <div class="detail-row">
        <span class="label">Location:</span> <span class="value">$incidentLocation</span>
      </div>
      <div class="detail-row">
        <span class="label">Description:</span>
        <p class="value">$incidentDescription</p>
      </div>
      ${incidentId != null ? '<p><strong>Incident ID:</strong> $incidentId</p>' : ''}
      <p>Please respond to this incident as soon as possible.</p>
    </div>
  </div>
</body>
</html>
''';
  }

  String _buildIncidentEmailText({
    required String incidentTitle,
    required String incidentType,
    required String incidentSeverity,
    required String incidentLocation,
    required String incidentDescription,
  }) {
    return '''
New Incident Reported

Title: $incidentTitle
Type: $incidentType
Severity: $incidentSeverity
Location: $incidentLocation

Description:
$incidentDescription

Please respond to this incident as soon as possible.
''';
  }

  String _buildSOSEmailTemplate({
    required String studentName,
    required String location,
    String? latitude,
    String? longitude,
  }) {
    final mapLink = (latitude != null && longitude != null)
        ? 'https://www.google.com/maps?q=$latitude,$longitude'
        : null;

    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <style>
    body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
    .container { max-width: 600px; margin: 0 auto; padding: 20px; }
    .header { background-color: #dc3545; color: white; padding: 20px; border-radius: 8px 8px 0 0; text-align: center; }
    .content { background-color: #f9f9f9; padding: 20px; border-radius: 0 0 8px 8px; }
    .alert { background-color: #fff3cd; border-left: 4px solid #ffc107; padding: 15px; margin: 20px 0; }
    .button { display: inline-block; padding: 12px 24px; background-color: #dc3545; color: white; text-decoration: none; border-radius: 4px; margin-top: 20px; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>🚨 EMERGENCY SOS</h1>
      <p style="font-size: 24px; margin: 0;">URGENT RESPONSE REQUIRED</p>
    </div>
    <div class="content">
      <div class="alert">
        <h2>Student: $studentName</h2>
        <p><strong>Location:</strong> $location</p>
        ${mapLink != null ? '<p><a href="$mapLink" class="button">View on Map</a></p>' : ''}
      </div>
      <p><strong>This is an emergency SOS activation. Immediate response is required.</strong></p>
      ${latitude != null && longitude != null ? '<p><strong>Coordinates:</strong> $latitude, $longitude</p>' : ''}
    </div>
  </div>
</body>
</html>
''';
  }

  String _buildSOSEmailText({
    required String studentName,
    required String location,
  }) {
    return '''
EMERGENCY SOS

Student: $studentName
Location: $location

This is an emergency SOS activation. Immediate response is required.
''';
  }

  String _buildUpdateEmailTemplate({
    required String incidentTitle,
    required String status,
    String? notes,
  }) {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <style>
    body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
    .container { max-width: 600px; margin: 0 auto; padding: 20px; }
    .header { background-color: #007bff; color: white; padding: 20px; border-radius: 8px 8px 0 0; }
    .content { background-color: #f9f9f9; padding: 20px; border-radius: 0 0 8px 8px; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>📋 Incident Update</h1>
    </div>
    <div class="content">
      <h2>$incidentTitle</h2>
      <p><strong>Status:</strong> $status</p>
      ${notes != null ? '<p><strong>Notes:</strong> $notes</p>' : ''}
    </div>
  </div>
</body>
</html>
''';
  }

  String _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return '#dc3545';
      case 'high':
        return '#fd7e14';
      case 'medium':
        return '#ffc107';
      case 'low':
        return '#28a745';
      default:
        return '#6c757d';
    }
  }
}