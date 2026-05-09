// ignore_for_file: unused_local_variable, avoid_print

/// Example code demonstrating how to use the AuthService
/// 
/// This file is for reference only and should not be imported in production code.
/// Copy the relevant code snippets to your actual implementation.
library;

import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../models/user.dart' as models;

class AuthExamples {
  final _authService = AuthService();

  /// Example 1: User Signup
  Future<void> exampleSignup() async {
    try {
      final result = await _authService.signup(
        name: 'John Doe',
        email: 'john.doe@university.edu',
        password: 'securePassword123',
        role: models.UserRole.student,
        studentId: '2024CS001', // Optional for students
      );

      final user = result['user'] as models.User;
      final token = result['token'] as String?;

      print('✅ Signup successful!');
      print('User ID: ${user.id}');
      print('Name: ${user.name}');
      print('Role: ${user.role.name}');
      
      // User is automatically logged in after signup
      // Navigate to appropriate dashboard based on role
      
    } catch (e) {
      print('❌ Signup failed: $e');
      // Show error message to user
    }
  }

  /// Example 2: User Login
  Future<void> exampleLogin() async {
    try {
      final result = await _authService.login(
        'john.doe@university.edu',
        'securePassword123',
      );

      final user = result['user'] as models.User;
      final token = result['token'] as String?;

      print('✅ Login successful!');
      print('Welcome back, ${user.name}!');

      // Navigate based on user role
      switch (user.role) {
        case models.UserRole.admin:
          // Navigate to admin dashboard
          break;
        case models.UserRole.security:
          // Navigate to security dashboard
          break;
        case models.UserRole.student:
          // Navigate to student dashboard
          break;
      }
      
    } catch (e) {
      print('❌ Login failed: $e');
      // Show error message to user
    }
  }

  /// Example 3: Check if User is Logged In
  Future<void> exampleCheckAuth() async {
    final isLoggedIn = await _authService.isLoggedIn();
    
    if (isLoggedIn) {
      print('✅ User is logged in');
      
      // Get current user details
      final user = await _authService.getCurrentUser();
      if (user != null) {
        print('Current user: ${user.name}');
        print('Role: ${user.role.name}');
      }
    } else {
      print('❌ User is not logged in');
      // Redirect to login screen
    }
  }

  /// Example 4: Logout
  Future<void> exampleLogout() async {
    try {
      await _authService.logout();
      print('✅ Logged out successfully');
      // Navigate to login screen
    } catch (e) {
      print('❌ Logout failed: $e');
    }
  }

  /// Example 5: Password Reset
  Future<void> examplePasswordReset() async {
    try {
      // Step 1: Request password reset email
      await _authService.forgotPassword('john.doe@university.edu');
      print('✅ Password reset email sent');
      print('Check your email for the reset link');
      
      // Step 2: After user clicks link in email, they can update password
      // This would typically be on a separate screen
      await _authService.updatePassword('newSecurePassword123');
      print('✅ Password updated successfully');
      
    } catch (e) {
      print('❌ Password reset failed: $e');
    }
  }

  /// Example 6: Listen to Auth State Changes
  void exampleAuthStateListener() {
    _authService.authStateChanges.listen((authState) {
      print('Auth state changed: ${authState.event}');
      
      switch (authState.event) {
        case AuthChangeEvent.signedIn:
          print('✅ User signed in');
          // Navigate to dashboard
          break;
          
        case AuthChangeEvent.signedOut:
          print('❌ User signed out');
          // Navigate to login screen
          break;
          
        case AuthChangeEvent.tokenRefreshed:
          print('🔄 Token refreshed');
          // Session is still valid
          break;
          
        case AuthChangeEvent.userUpdated:
          print('👤 User profile updated');
          // Refresh user data
          break;
          
        default:
          print('Auth event: ${authState.event}');
      }
    });
  }

  /// Example 7: Get Current User
  Future<void> exampleGetCurrentUser() async {
    final user = await _authService.getCurrentUser();
    
    if (user != null) {
      print('Current User:');
      print('  ID: ${user.id}');
      print('  Name: ${user.name}');
      print('  Email: ${user.email}');
      print('  Role: ${user.role.name}');
      print('  Student ID: ${user.studentId ?? 'N/A'}');
      print('  Active: ${user.isActive}');
      print('  Created: ${user.createdAt}');
    } else {
      print('No user logged in');
    }
  }

  /// Example 8: Error Handling
  Future<void> exampleErrorHandling() async {
    try {
      await _authService.login('invalid@email.com', 'wrongpassword');
    } catch (e) {
      final errorMessage = e.toString();
      
      // Handle specific error cases
      if (errorMessage.contains('Invalid credentials')) {
        print('❌ Invalid email or password');
      } else if (errorMessage.contains('Email not confirmed')) {
        print('❌ Please verify your email first');
      } else if (errorMessage.contains('User not found')) {
        print('❌ No account found with this email');
      } else if (errorMessage.contains('Too many requests')) {
        print('❌ Too many login attempts. Please try again later');
      } else {
        print('❌ An error occurred: $errorMessage');
      }
    }
  }

  /// Example 9: Signup with Different Roles
  Future<void> exampleRoleBasedSignup() async {
    // Student signup
    await _authService.signup(
      name: 'Student Name',
      email: 'student@university.edu',
      password: 'password123',
      role: models.UserRole.student,
      studentId: '2024CS001',
    );

    // Security officer signup (typically done by admin)
    await _authService.signup(
      name: 'Officer Name',
      email: 'officer@university.edu',
      password: 'password123',
      role: models.UserRole.security,
    );

    // Admin signup (typically done by super admin)
    await _authService.signup(
      name: 'Admin Name',
      email: 'admin@university.edu',
      password: 'password123',
      role: models.UserRole.admin,
    );
  }

  /// Example 10: Complete Login Flow with UI Feedback
  Future<bool> exampleCompleteLoginFlow(String email, String password) async {
    // Show loading indicator
    print('⏳ Logging in...');
    
    try {
      final result = await _authService.login(email, password);
      final user = result['user'] as models.User;
      
      // Hide loading indicator
      // Show success message
      print('✅ Welcome back, ${user.name}!');
      
      // Navigate to appropriate dashboard
      return true;
      
    } catch (e) {
      // Hide loading indicator
      // Show error message
      print('❌ Login failed: $e');
      return false;
    }
  }
}

/// Usage in a Flutter Widget:
/// 
/// ```dart
/// class LoginScreen extends StatefulWidget {
///   @override
///   _LoginScreenState createState() => _LoginScreenState();
/// }
/// 
/// class _LoginScreenState extends State<LoginScreen> {
///   final _authService = AuthService();
///   final _emailController = TextEditingController();
///   final _passwordController = TextEditingController();
///   bool _isLoading = false;
/// 
///   Future<void> _handleLogin() async {
///     setState(() => _isLoading = true);
/// 
///     try {
///       final result = await _authService.login(
///         _emailController.text.trim(),
///         _passwordController.text,
///       );
/// 
///       final user = result['user'] as models.User;
///       
///       // Navigate to dashboard
///       Navigator.pushReplacement(
///         context,
///         MaterialPageRoute(builder: (_) => DashboardScreen(user: user)),
///       );
///       
///     } catch (e) {
///       ScaffoldMessenger.of(context).showSnackBar(
///         SnackBar(content: Text('Login failed: $e')),
///       );
///     } finally {
///       setState(() => _isLoading = false);
///     }
///   }
/// 
///   @override
///   Widget build(BuildContext context) {
///     return Scaffold(
///       body: Column(
///         children: [
///           TextField(
///             controller: _emailController,
///             decoration: InputDecoration(labelText: 'Email'),
///           ),
///           TextField(
///             controller: _passwordController,
///             decoration: InputDecoration(labelText: 'Password'),
///             obscureText: true,
///           ),
///           ElevatedButton(
///             onPressed: _isLoading ? null : _handleLogin,
///             child: _isLoading 
///               ? CircularProgressIndicator() 
///               : Text('Login'),
///           ),
///         ],
///       ),
///     );
///   }
/// }
/// ```

