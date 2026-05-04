import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart' as models;
import 'storage_service.dart';

class AuthService {
  final _storage = StorageService.instance;
  final _supabase = Supabase.instance.client;

  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      if (email.isEmpty || password.isEmpty) {
        throw Exception('Email and password are required');
      }

      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw Exception('Login failed. Please check your credentials.');
      }

      Map<String, dynamic> userProfile;
      try {
        final profileResult = await _supabase
            .from('users')
            .select()
            .eq('id', response.user!.id)
            .maybeSingle();

        if (profileResult == null) {
          final defaultRole = response.user!.userMetadata?['role'] ?? 'student';
          final defaultName = response.user!.userMetadata?['name'] ?? response.user!.email?.split('@')[0] ?? 'User';

          userProfile = {
            'id': response.user!.id,
            'name': defaultName,
            'email': response.user!.email ?? email,
            'student_id': null,
            'phone': null,
            'residence': null,
            'role': defaultRole,
            'profile_image': null,
            'created_at': DateTime.now().toIso8601String(),
            'is_active': true,
          };

          await _supabase.from('users').insert(userProfile);
        } else {
          userProfile = profileResult;
        }
      } catch (e) {
        throw Exception('Failed to load user profile. Please contact support.');
      }

      final user = models.User(
        id: response.user!.id,
        name: userProfile['name'] ?? 'User',
        email: response.user!.email ?? email,
        studentId: userProfile['student_id'],
        phone: userProfile['phone'],
        residence: userProfile['residence'],
        role: models.UserRoleExtension.fromString(userProfile['role'] ?? 'student'),
        profileImage: userProfile['profile_image'],
        createdAt: DateTime.parse(userProfile['created_at']),
        isActive: userProfile['is_active'] ?? true,
      );

      await _saveToken(response.session?.accessToken ?? '');
      await _saveUser(user);

      return {
        'token': response.session?.accessToken,
        'user': user,
      };
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Login failed: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> signup({
    required String name,
    required String email,
    required String password,
    required models.UserRole role,
    String? studentId,
  }) async {
    try {
      if (name.isEmpty || email.isEmpty || password.isEmpty) {
        throw Exception('All fields are required');
      }

      if (password.length < 6) {
        throw Exception('Password must be at least 6 characters');
      }

      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name,
          'role': role.name,
        },
      );

      if (response.user == null) {
        throw Exception('Signup failed. Please try again.');
      }

      final userProfileData = {
        'id': response.user!.id,
        'name': name,
        'email': email,
        'student_id': studentId,
        'role': role.name,
        'created_at': DateTime.now().toIso8601String(),
        'is_active': true,
      };

      await _supabase.from('users').insert(userProfileData);

      final user = models.User(
        id: response.user!.id,
        name: name,
        email: email,
        studentId: studentId,
        phone: null,
        residence: null,
        role: role,
        createdAt: DateTime.now(),
        isActive: true,
      );

      await _saveToken(response.session?.accessToken ?? '');
      await _saveUser(user);

      return {
        'token': response.session?.accessToken,
        'user': user,
      };
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Signup failed: ${e.toString()}');
    }
  }

  Future<void> forgotPassword(String email) async {
    try {
      if (email.isEmpty) {
        throw Exception('Email is required');
      }
      await _supabase.auth.resetPasswordForEmail(email);
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Password reset failed: ${e.toString()}');
    }
  }

  Future<void> updatePassword(String newPassword) async {
    try {
      if (newPassword.isEmpty) {
        throw Exception('New password is required');
      }
      if (newPassword.length < 6) {
        throw Exception('Password must be at least 6 characters');
      }
      await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Password update failed: ${e.toString()}');
    }
  }

  Future<void> logout() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      // Continue with local cleanup even if signOut fails
    }
    _storage.remove(_tokenKey);
    _storage.remove(_userKey);
    _storage.remove('user_role');
  }

  Future<bool> isLoggedIn() async {
    final session = _supabase.auth.currentSession;
    return session != null;
  }

  Future<models.User?> getCurrentUser() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return null;

      final userProfileResult = await _supabase
          .from('users')
          .select()
          .eq('id', currentUser.id)
          .maybeSingle();

      if (userProfileResult == null) return null;

      final userProfile = userProfileResult;

      return models.User(
        id: currentUser.id,
        name: userProfile['name'] ?? 'User',
        email: currentUser.email ?? '',
        studentId: userProfile['student_id'],
        role: models.UserRoleExtension.fromString(userProfile['role'] ?? 'student'),
        profileImage: userProfile['profile_image'],
        createdAt: DateTime.parse(userProfile['created_at']),
        isActive: userProfile['is_active'] ?? true,
      );
    } catch (e) {
      return null;
    }
  }

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  Future<void> _saveToken(String token) async {
    await _storage.setString(_tokenKey, token);
  }

  Future<void> _saveUser(models.User user) async {
    await _storage.setString(_userKey, user.toJson().toString());
    await _storage.setString('user_role', user.role.name);
  }
}

