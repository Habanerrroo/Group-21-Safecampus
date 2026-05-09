import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/theme.dart';
import 'config/supabase_config.dart';
import 'services/storage_service.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/student/enhanced_student_dashboard.dart';
import 'screens/security/enhanced_security_dashboard.dart';
import 'screens/admin/enhanced_admin_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Storage Service
  await StorageService.instance.init();

  // Initialize Supabase
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.primary,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const SafeCampusApp());
}

class SafeCampusApp extends StatelessWidget {
  const SafeCampusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SafeCampus AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const AppEntryPoint(),
    );
  }
}

class AppEntryPoint extends StatefulWidget {
  const AppEntryPoint({super.key});

  @override
  State<AppEntryPoint> createState() => _AppEntryPointState();
}

class _AppEntryPointState extends State<AppEntryPoint> {
  @override
  Widget build(BuildContext context) {
    final storage = StorageService.instance;
    final supabase = Supabase.instance.client;

    // Check if onboarding completed
    final onboardingCompleted = storage.getBool('onboarding_completed');

    if (!onboardingCompleted) {
      return const OnboardingScreen();
    }

    // Check if user is logged in with Supabase
    final session = supabase.auth.currentSession;

    if (session == null) {
      return const LoginScreen();
    }

    // Get user role and navigate to appropriate dashboard
    final userRole = storage.getString('user_role') ?? 'student';

    switch (userRole) {
      case 'admin':
            return const EnhancedAdminDashboard();
      case 'security':
        return const EnhancedSecurityDashboard();
      case 'student':
      default:
        return const EnhancedStudentDashboard();
    }
  }
}
