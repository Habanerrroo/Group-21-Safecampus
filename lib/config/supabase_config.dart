library;

class SupabaseConfig {

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://otauiydzyxomodpmgggc.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im90YXVpeWR6eXhvbW9kcG1nZ2djIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQwNDI5OTEsImV4cCI6MjA3OTYxODk5MX0.GNYPlV7Ab2yhGzD4pCYPBc5-mmeVYPnE0JXu5wgz6-s',
  );

  // Validate configuration
  static bool get isConfigured {
    return supabaseUrl != 'https://otauiydzyxomodpmgggc.supabase.co' &&
        supabaseAnonKey != 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im90YXVpeWR6eXhvbW9kcG1nZ2djIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQwNDI5OTEsImV4cCI6MjA3OTYxODk5MX0.GNYPlV7Ab2yhGzD4pCYPBc5-mmeVYPnE0JXu5wgz6-s' &&
        supabaseUrl.isNotEmpty &&
        supabaseAnonKey.isNotEmpty;
  }

  // Helper method to check if using default values
  static bool get isUsingDefaults {
    return supabaseUrl == 'https://otauiydzyxomodpmgggc.supabase.co' ||
        supabaseAnonKey == 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im90YXVpeWR6eXhvbW9kcG1nZ2djIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQwNDI5OTEsImV4cCI6MjA3OTYxODk5MX0.GNYPlV7Ab2yhGzD4pCYPBc5-mmeVYPnE0JXu5wgz6-s';
  }
}
