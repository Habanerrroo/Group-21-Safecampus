import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:developer' as developer;
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
    developer.log('📤 UPLOADING FILE TO STORAGE', name: 'StorageServiceUpload');
    developer.log('🪣 Bucket: $bucket', name: 'StorageServiceUpload');
    developer.log('📁 File Path: $filePath', name: 'StorageServiceUpload');

    try {
      final file = File(filePath);
      if (!await file.exists()) {
        developer.log('❌ File does not exist: $filePath', name: 'StorageServiceUpload');
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

      developer.log('✅ File uploaded: $response', name: 'StorageServiceUpload');

      // Get public URL
      final publicUrl = _supabase.storage
          .from(bucket)
          .getPublicUrl(uniqueFileName);

      developer.log('✅ Public URL: $publicUrl', name: 'StorageServiceUpload');
      return publicUrl;
    } catch (e) {
      developer.log('❌ Error uploading file: $e', name: 'StorageServiceUpload');
      return null;
    }
  }

  // Upload incident photo
  Future<String?> uploadIncidentPhoto({
    required String incidentId,
    required String filePath,
  }) async {
    developer.log('📸 UPLOADING INCIDENT PHOTO', name: 'StorageServiceUpload');
    
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
    developer.log('👤 UPLOADING PROFILE PHOTO', name: 'StorageServiceUpload');
    
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
    developer.log('🗑️ DELETING FILE FROM STORAGE', name: 'StorageServiceUpload');
    developer.log('🪣 Bucket: $bucket', name: 'StorageServiceUpload');
    developer.log('📁 File: $fileName', name: 'StorageServiceUpload');

    try {
      await _supabase.storage
          .from(bucket)
          .remove([fileName]);

      developer.log('✅ File deleted successfully', name: 'StorageServiceUpload');
      return true;
    } catch (e) {
      developer.log('❌ Error deleting file: $e', name: 'StorageServiceUpload');
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
      developer.log('❌ Error creating temp file: $e', name: 'StorageServiceUpload');
      return null;
    }
  }
}


