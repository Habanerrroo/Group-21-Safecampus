library;

class SupabaseConfig {

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://rwyhxriapfxkpnrgcptz.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ3eWh4cmlhcGZ4a3BucmdjcHR6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjY0ODUwOTYsImV4cCI6MjA4MjA2MTA5Nn0.H2ps_AKAHjN0DWu4atFK9M48ihtq1DYbBDb9bKBlv_A',
  );

  // Validate configuration
  static bool get isConfigured {
    return supabaseUrl != 'https://rwyhxriapfxkpnrgcptz.supabase.co' &&
        supabaseAnonKey != 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ3eWh4cmlhcGZ4a3BucmdjcHR6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjY0ODUwOTYsImV4cCI6MjA4MjA2MTA5Nn0.H2ps_AKAHjN0DWu4atFK9M48ihtq1DYbBDb9bKBlv_A' &&
        supabaseUrl.isNotEmpty &&
        supabaseAnonKey.isNotEmpty;
  }

  // Helper method to check if using default values
  static bool get isUsingDefaults {
    return supabaseUrl == 'https://rwyhxriapfxkpnrgcptz.supabase.co' ||
        supabaseAnonKey == 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ3eWh4cmlhcGZ4a3BucmdjcHR6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjY0ODUwOTYsImV4cCI6MjA4MjA2MTA5Nn0.H2ps_AKAHjN0DWu4atFK9M48ihtq1DYbBDb9bKBlv_A';
  }
}