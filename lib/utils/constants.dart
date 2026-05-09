// App Constants

class AppConstants {
  // App Info
  static const String appName = 'SafeCampus AI';
  static const String appTagline = 'Campus Safety Intelligence Platform';
  static const String appVersion = '1.0.0';

  // Emergency
  static const int emergencyHoldDuration = 3000; // milliseconds
  
  // API Endpoints (to be configured)
  static const String apiBaseUrl = 'https://api.safecampus.example.com';
  static const String wsBaseUrl = 'wss://ws.safecampus.example.com';
  
  // Timeouts
  static const int apiTimeout = 30; // seconds
  static const int connectionTimeout = 10; // seconds
  
  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  
  // Map
  static const double defaultMapZoom = 15.0;
  static const double minMapZoom = 10.0;
  static const double maxMapZoom = 20.0;
  
  // Incident Categories
  static const List<String> incidentCategories = [
    'theft',
    'assault',
    'harassment',
    'fire',
    'medical',
    'other',
  ];
  
  // Alert Types
  static const List<String> alertTypes = [
    'critical',
    'warning',
    'info',
    'all-clear',
  ];
  
  // User Roles
  static const String roleStudent = 'student';
  static const String roleSecurity = 'security';
  static const String roleAdmin = 'admin';
  
  // Storage Keys
  static const String keyUserToken = 'user_token';
  static const String keyUserRole = 'user_role';
  static const String keyUserId = 'user_id';
  static const String keyUserName = 'user_name';
  
  // Animation Durations
  static const int shortAnimationDuration = 200;
  static const int mediumAnimationDuration = 300;
  static const int longAnimationDuration = 500;
}

