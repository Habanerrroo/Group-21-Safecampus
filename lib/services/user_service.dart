import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:developer' as developer;
import '../models/user.dart' as models;
import 'storage_service_upload.dart';

class UserService {
  final _supabase = Supabase.instance.client;
  final _storageService = StorageServiceUpload();

  // Get user profile by ID
  Future<models.User?> getUserProfile(String userId) async {
    developer.log('👤 FETCHING USER PROFILE', name: 'UserService');
    developer.log('🔍 User ID: $userId', name: 'UserService');

    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      developer.log('✅ User profile fetched', name: 'UserService');
      developer.log('📋 Data: $response', name: 'UserService');

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
      developer.log('❌ Error fetching user profile: $e', name: 'UserService');
      return null;
    }
  }

  // Update user profile
  Future<bool> updateUserProfile({
    required String userId,
    String? name,
    String? studentId,
    String? phone,
    String? residence,
    String? profileImage,
  }) async {
    developer.log('📝 UPDATING USER PROFILE', name: 'UserService');
    developer.log('🔍 User ID: $userId', name: 'UserService');

    try {
      final updates = <String, dynamic>{};
      if (name != null && name.isNotEmpty) updates['name'] = name;
      if (studentId != null && studentId.isNotEmpty) updates['student_id'] = studentId;
      // Skip phone update - column may not exist in database
      // if (phone != null && phone.isNotEmpty) updates['phone'] = phone;
      // Residence column should exist, but handle gracefully if it doesn't
      if (residence != null && residence.isNotEmpty) {
        updates['residence'] = residence;
      }
      if (profileImage != null && profileImage.isNotEmpty) updates['profile_image'] = profileImage;

      developer.log('📋 Updates: $updates', name: 'UserService');

      await _supabase
          .from('users')
          .update(updates)
          .eq('id', userId);

      developer.log('✅ Profile updated successfully', name: 'UserService');
      return true;
    } catch (e) {
      developer.log('❌ Error updating profile: $e', name: 'UserService');
      return false;
    }
  }

  // Get current logged-in user
  Future<models.User?> getCurrentUser() async {
    developer.log('👤 GETTING CURRENT USER', name: 'UserService');

    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        developer.log('❌ No user logged in', name: 'UserService');
        return null;
      }

      return await getUserProfile(currentUser.id);
    } catch (e) {
      developer.log('❌ Error getting current user: $e', name: 'UserService');
      return null;
    }
  }

  // Upload profile photo
  Future<String?> uploadProfilePhoto({
    required String userId,
    required String filePath,
  }) async {
    developer.log('📸 UPLOADING PROFILE PHOTO', name: 'UserService');
    developer.log('👤 User ID: $userId', name: 'UserService');

    try {
      // Upload to Supabase Storage
      final photoUrl = await _storageService.uploadProfilePhoto(
        userId: userId,
        filePath: filePath,
      );

      if (photoUrl == null) {
        developer.log('❌ Failed to upload photo to storage', name: 'UserService');
        return null;
      }

      // Update user profile with photo URL
      final success = await updateUserProfile(
        userId: userId,
        profileImage: photoUrl,
      );

      if (success) {
        developer.log('✅ Profile photo uploaded successfully', name: 'UserService');
        return photoUrl;
      } else {
        developer.log('❌ Failed to update profile with photo URL', name: 'UserService');
        return null;
      }
    } catch (e) {
      developer.log('❌ Error uploading profile photo: $e', name: 'UserService');
      return null;
    }
  }
}

