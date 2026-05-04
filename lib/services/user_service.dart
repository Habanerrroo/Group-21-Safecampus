import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart' as models;
import 'storage_service_upload.dart';

class UserService {
  final _supabase = Supabase.instance.client;
  final _storageService = StorageServiceUpload();

  Future<models.User?> getUserProfile(String userId) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      return models.User(
        id: response['id'],
        name: response['name'],
        email: response['email'],
        studentId: response['student_id'],
        phone: response['phone'],
        residence: response['residence'],
        role: models.UserRoleExtension.fromString(response['role']),
        profileImage: response['profile_image'],
        createdAt: DateTime.parse(response['created_at']),
        isActive: response['is_active'] ?? true,
      );
    } catch (e) {
      return null;
    }
  }

  Future<bool> updateUserProfile({
    required String userId,
    String? name,
    String? studentId,
    String? phone,
    String? residence,
    String? profileImage,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (name != null && name.isNotEmpty) updates['name'] = name;
      if (studentId != null && studentId.isNotEmpty) updates['student_id'] = studentId;
      if (residence != null && residence.isNotEmpty) updates['residence'] = residence;
      if (profileImage != null && profileImage.isNotEmpty) updates['profile_image'] = profileImage;

      await _supabase
          .from('users')
          .update(updates)
          .eq('id', userId);

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<models.User?> getCurrentUser() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return null;
      return await getUserProfile(currentUser.id);
    } catch (e) {
      return null;
    }
  }

  Future<String?> uploadProfilePhoto({
    required String userId,
    required String filePath,
  }) async {
    try {
      final photoUrl = await _storageService.uploadProfilePhoto(
        userId: userId,
        filePath: filePath,
      );

      if (photoUrl == null) return null;

      final success = await updateUserProfile(
        userId: userId,
        profileImage: photoUrl,
      );

      return success ? photoUrl : null;
    } catch (e) {
      return null;
    }
  }
}

