import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class StorageServiceUpload {
  final _supabase = Supabase.instance.client;

  // Upload a file to Supabase Storage
  Future<String?> uploadFile({
    required String bucket,
    required String filePath,
    String? fileName,
    Map<String, String>? metadata,
  }) async {

    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return null;
      }

      // Generate unique filename if not provided
      final uniqueFileName = fileName ??
          '${DateTime.now().millisecondsSinceEpoch}_${path.basename(filePath)}';

      // Read file bytes
      final fileBytes = await file.readAsBytes();

      // Upload to Supabase Storage
      final response = await _supabase.storage
          .from(bucket)
          .uploadBinary(
        uniqueFileName,
        fileBytes,
        fileOptions: FileOptions(
          contentType: _getContentType(filePath),
          metadata: metadata,
        ),
      );


      // Get public URL
      final publicUrl = _supabase.storage
          .from(bucket)
          .getPublicUrl(uniqueFileName);

      return publicUrl;
    } catch (e) {
      return null;
    }
  }

  // Upload incident photo
  Future<String?> uploadIncidentPhoto({
    required String incidentId,
    required String filePath,
  }) async {

    final currentUser = _supabase.auth.currentUser;
    final fileName = 'incidents/${incidentId}/${DateTime.now().millisecondsSinceEpoch}.jpg';

    return await uploadFile(
      bucket: 'incident-media',
      filePath: filePath,
      fileName: fileName,
      metadata: {
        'incident_id': incidentId,
        'uploaded_by': currentUser?.id ?? 'anonymous',
        'uploaded_at': DateTime.now().toIso8601String(),
      },
    );
  }

  // Upload profile photo
  Future<String?> uploadProfilePhoto({
    required String userId,
    required String filePath,
  }) async {

    final fileName = 'profiles/$userId/${DateTime.now().millisecondsSinceEpoch}.jpg';

    return await uploadFile(
      bucket: 'profile-images',
      filePath: filePath,
      fileName: fileName,
      metadata: {
        'user_id': userId,
        'uploaded_at': DateTime.now().toIso8601String(),
      },
    );
  }

  // Delete a file from storage
  Future<bool> deleteFile({
    required String bucket,
    required String fileName,
  }) async {

    try {
      await _supabase.storage
          .from(bucket)
          .remove([fileName]);

      return true;
    } catch (e) {
      return false;
    }
  }

  // Get content type from file extension
  String _getContentType(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    switch (extension) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.mp4':
        return 'video/mp4';
      case '.mov':
        return 'video/quicktime';
      case '.mp3':
        return 'audio/mpeg';
      case '.wav':
        return 'audio/wav';
      default:
        return 'application/octet-stream';
    }
  }

  // Create temporary file from bytes (for image processing)
  Future<String?> createTempFile(List<int> bytes, String extension) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}$extension';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(bytes);
      return file.path;
    } catch (e) {
      return null;
    }
  }
}


