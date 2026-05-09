import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:developer' as developer;
import '../models/user.dart' as models;
import 'storage_service.dart';

class AuthService {
  final _storage = StorageService.instance;
  final _supabase = Supabase.instance.client;
  
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  // Login with Supabase
  Future<Map<String, dynamic>> login(String email, String password) async {
    developer.log('🔐 LOGIN ATTEMPT', name: 'AuthService');
    developer.log('📧 Email: $email', name: 'AuthService');
    
    try {
      if (email.isEmpty || password.isEmpty) {
        developer.log('❌ Validation failed: Empty email or password', name: 'AuthService');
        throw Exception('Email and password are required');
      }

      developer.log('📡 Calling Supabase signInWithPassword...', name: 'AuthService');
      
      // Sign in with Supabase
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      developer.log('✅ Supabase auth response received', name: 'AuthService');
      developer.log('👤 User ID: ${response.user?.id}', name: 'AuthService');
      developer.log('📧 User Email: ${response.user?.email}', name: 'AuthService');
      developer.log('🎫 Session exists: ${response.session != null}', name: 'AuthService');

      if (response.user == null) {
        developer.log('❌ No user in response', name: 'AuthService');
        throw Exception('Login failed. Please check your credentials.');
      }

      developer.log('📡 Fetching user profile from database...', name: 'AuthService');
      developer.log('🔍 Querying users table for ID: ${response.user!.id}', name: 'AuthService');
      
      // Fetch user profile from database (use maybeSingle to handle missing profiles)
      Map<String, dynamic> userProfile;
      try {
        final profileResult = await _supabase
            .from('users')
            .select()
            .eq('id', response.user!.id)
            .maybeSingle();

        if (profileResult == null) {
          // Profile doesn't exist - create it with default values
          developer.log('⚠️ User profile not found in database, creating default profile...', name: 'AuthService');
          
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
          
          developer.log('📋 Creating profile with data: $userProfile', name: 'AuthService');
          
          await _supabase.from('users').insert(userProfile);
          
          developer.log('✅ Default user profile created', name: 'AuthService');
        } else {
          userProfile = profileResult;
          developer.log('✅ User profile fetched successfully', name: 'AuthService');
        }
      } catch (e) {
        developer.log('❌ Error fetching/creating user profile: $e', name: 'AuthService');
        throw Exception('Failed to load user profile. Please contact support.');
      }

      developer.log('📋 Profile data: $userProfile', name: 'AuthService');

      // Create user object
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

      developer.log('👤 User object created: ${user.name} (${user.role.name})', name: 'AuthService');
      developer.log('💾 Saving to local storage...', name: 'AuthService');

      // Save to local storage
      await _saveToken(response.session?.accessToken ?? '');
      await _saveUser(user);

      developer.log('✅ LOGIN SUCCESSFUL', name: 'AuthService');
      developer.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━', name: 'AuthService');

      return {
        'token': response.session?.accessToken,
        'user': user,
      };
    } on AuthException catch (e) {
      developer.log('❌ AUTH EXCEPTION: ${e.message}', name: 'AuthService');
      developer.log('📋 Status Code: ${e.statusCode}', name: 'AuthService');
      developer.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━', name: 'AuthService');
      throw Exception(e.message);
    } catch (e) {
      developer.log('❌ GENERAL EXCEPTION: ${e.toString()}', name: 'AuthService');
      developer.log('📋 Error Type: ${e.runtimeType}', name: 'AuthService');
      developer.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━', name: 'AuthService');
      throw Exception('Login failed: ${e.toString()}');
    }
  }

  // Signup with Supabase
  Future<Map<String, dynamic>> signup({
    required String name,
    required String email,
    required String password,
    required models.UserRole role,
    String? studentId,
  }) async {
    developer.log('📝 SIGNUP ATTEMPT', name: 'AuthService');
    developer.log('👤 Name: $name', name: 'AuthService');
    developer.log('📧 Email: $email', name: 'AuthService');
    developer.log('🎭 Role: ${role.name}', name: 'AuthService');
    developer.log('🎓 Student ID: ${studentId ?? "N/A"}', name: 'AuthService');
    
    try {
      // Validation
      if (name.isEmpty || email.isEmpty || password.isEmpty) {
        developer.log('❌ Validation failed: Empty required fields', name: 'AuthService');
        throw Exception('All fields are required');
      }

      if (password.length < 6) {
        developer.log('❌ Validation failed: Password too short', name: 'AuthService');
        throw Exception('Password must be at least 6 characters');
      }

      developer.log('📡 Calling Supabase signUp...', name: 'AuthService');

      // Sign up with Supabase Auth
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name,
          'role': role.name,
        },
      );

      developer.log('✅ Supabase auth signup response received', name: 'AuthService');
      developer.log('👤 User ID: ${response.user?.id}', name: 'AuthService');
      developer.log('📧 User Email: ${response.user?.email}', name: 'AuthService');
      developer.log('🎫 Session exists: ${response.session != null}', name: 'AuthService');

      if (response.user == null) {
        developer.log('❌ No user in response', name: 'AuthService');
        throw Exception('Signup failed. Please try again.');
      }

      developer.log('💾 Creating user profile in database...', name: 'AuthService');
      
      final userProfileData = {
        'id': response.user!.id,
        'name': name,
        'email': email,
        'student_id': studentId,
        'role': role.name,
        'created_at': DateTime.now().toIso8601String(),
        'is_active': true,
      };
      
      developer.log('📋 Profile data to insert: $userProfileData', name: 'AuthService');

      // Create user profile in database
      await _supabase.from('users').insert(userProfileData);

      developer.log('✅ User profile created in database', name: 'AuthService');

      // Create user object
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

      developer.log('👤 User object created: ${user.name} (${user.role.name})', name: 'AuthService');
      developer.log('💾 Saving to local storage...', name: 'AuthService');

      // Save to local storage
      await _saveToken(response.session?.accessToken ?? '');
      await _saveUser(user);

      developer.log('✅ SIGNUP SUCCESSFUL', name: 'AuthService');
      developer.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━', name: 'AuthService');

      return {
        'token': response.session?.accessToken,
        'user': user,
      };
    } on AuthException catch (e) {
      developer.log('❌ AUTH EXCEPTION: ${e.message}', name: 'AuthService');
      developer.log('📋 Status Code: ${e.statusCode}', name: 'AuthService');
      developer.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━', name: 'AuthService');
      throw Exception(e.message);
    } catch (e) {
      developer.log('❌ GENERAL EXCEPTION: ${e.toString()}', name: 'AuthService');
      developer.log('📋 Error Type: ${e.runtimeType}', name: 'AuthService');
      developer.log('📋 Stack Trace: ${StackTrace.current}', name: 'AuthService');
      developer.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━', name: 'AuthService');
      throw Exception('Signup failed: ${e.toString()}');
    }
  }

  // Forgot password with Supabase
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

  // Update password with Supabase
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

  // Logout
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

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final session = _supabase.auth.currentSession;
    return session != null;
  }

  // Get current user
  Future<models.User?> getCurrentUser() async {
    developer.log('👤 GET CURRENT USER', name: 'AuthService');
    
    try {
      final currentUser = _supabase.auth.currentUser;
      
      if (currentUser == null) {
        developer.log('❌ No current user in session', name: 'AuthService');
        return null;
      }

      developer.log('✅ Current user found: ${currentUser.id}', name: 'AuthService');
      developer.log('📡 Fetching user profile from database...', name: 'AuthService');

      // Fetch user profile from database (use maybeSingle to handle missing profiles)
      final userProfileResult = await _supabase
          .from('users')
          .select()
          .eq('id', currentUser.id)
          .maybeSingle();

      if (userProfileResult == null) {
        developer.log('❌ User profile not found in database', name: 'AuthService');
        return null;
      }

      developer.log('✅ User profile fetched: ${userProfileResult['name']}', name: 'AuthService');
      
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
      developer.log('❌ Error getting current user: ${e.toString()}', name: 'AuthService');
      return null;
    }
  }
  
  // Get Supabase auth state stream
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // Private helper methods
  Future<void> _saveToken(String token) async {
    await _storage.setString(_tokenKey, token);
  }

  Future<void> _saveUser(models.User user) async {
    await _storage.setString(_userKey, user.toJson().toString());
    // Also save the role separately for easy access
    await _storage.setString('user_role', user.role.name);
  }
}
