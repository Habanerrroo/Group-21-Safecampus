import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

/// Utility class to test Supabase connection and configuration
class SupabaseTest {
  static final _supabase = Supabase.instance.client;

  /// Test if Supabase is properly configured
  static Future<Map<String, dynamic>> testConnection() async {
    final results = <String, dynamic>{};

    // 1. Check configuration
    results['config_valid'] = SupabaseConfig.isConfigured;
    results['using_defaults'] = SupabaseConfig.isUsingDefaults;
    results['url'] = SupabaseConfig.supabaseUrl;

    if (SupabaseConfig.isUsingDefaults) {
      results['error'] = 'Using default configuration. Please update credentials.';
      return results;
    }

    try {
      // 2. Test database connection
      final response = await _supabase
          .from('users')
          .select('count')
          .limit(1)
          .timeout(const Duration(seconds: 5));

      results['database_connected'] = true;
      results['database_response'] = response;
    } catch (e) {
      results['database_connected'] = false;
      results['database_error'] = e.toString();
    }

    try {
      // 3. Test auth service
      final session = _supabase.auth.currentSession;
      results['auth_initialized'] = true;
      results['current_session'] = session != null ? 'Active' : 'No session';
    } catch (e) {
      results['auth_initialized'] = false;
      results['auth_error'] = e.toString();
    }

    try {
      // 4. Test storage
      final buckets = await _supabase.storage.listBuckets();
      results['storage_accessible'] = true;
      results['storage_buckets'] = buckets.length;
    } catch (e) {
      results['storage_accessible'] = false;
      results['storage_error'] = e.toString();
    }

    return results;
  }

  /// Pretty print test results
  static String formatResults(Map<String, dynamic> results) {
    final buffer = StringBuffer();
    buffer.writeln('=== Supabase Connection Test ===\n');

    // Configuration
    buffer.writeln('📋 Configuration:');
    buffer.writeln('  ✓ Valid: ${results['config_valid']}');
    buffer.writeln('  ⚠ Using Defaults: ${results['using_defaults']}');
    buffer.writeln('  🔗 URL: ${results['url']}\n');

    if (results['using_defaults'] == true) {
      buffer.writeln('❌ ERROR: ${results['error']}\n');
      buffer.writeln('Please update lib/config/supabase_config.dart with your credentials.');
      return buffer.toString();
    }

    // Database
    buffer.writeln('💾 Database:');
    if (results['database_connected'] == true) {
      buffer.writeln('  ✅ Connected');
    } else {
      buffer.writeln('  ❌ Connection Failed');
      buffer.writeln('  Error: ${results['database_error']}');
    }
    buffer.writeln();

    // Auth
    buffer.writeln('🔐 Authentication:');
    if (results['auth_initialized'] == true) {
      buffer.writeln('  ✅ Initialized');
      buffer.writeln('  Session: ${results['current_session']}');
    } else {
      buffer.writeln('  ❌ Initialization Failed');
      buffer.writeln('  Error: ${results['auth_error']}');
    }
    buffer.writeln();

    // Storage
    buffer.writeln('📦 Storage:');
    if (results['storage_accessible'] == true) {
      buffer.writeln('  ✅ Accessible');
      buffer.writeln('  Buckets: ${results['storage_buckets']}');
    } else {
      buffer.writeln('  ❌ Access Failed');
      buffer.writeln('  Error: ${results['storage_error']}');
    }
    buffer.writeln();

    // Summary
    final allPassed = results['config_valid'] == true &&
        results['using_defaults'] == false &&
        results['database_connected'] == true &&
        results['auth_initialized'] == true &&
        results['storage_accessible'] == true;

    if (allPassed) {
      buffer.writeln('✅ All tests passed! Supabase is ready to use.');
    } else {
      buffer.writeln('⚠️  Some tests failed. Please check the errors above.');
    }

    return buffer.toString();
  }

  /// Run all tests and print results
  static Future<void> runTests() async {
    print('Running Supabase connection tests...\n');
    
    try {
      final results = await testConnection();
      print(formatResults(results));
    } catch (e) {
      print('❌ Test failed with error: $e');
    }
  }
}

