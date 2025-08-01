import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'services/supabase_service.dart';
import 'controllers/auth_controller.dart';
import 'controllers/level_controller.dart';
import 'controllers/admin_controller.dart';
import 'views/auth/login_screen.dart';
import 'views/auth/register_screen.dart';
import 'views/dashboard/student_dashboard.dart';
import 'views/dashboard/staff_dashboard.dart';
import 'views/dashboard/admin_dashboard.dart';
import 'views/profile/edit_profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await SupabaseService.initialize();
  
  runApp(const StudentsCodingPortal());
}

class StudentsCodingPortal extends StatelessWidget {
  const StudentsCodingPortal({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => LevelController()),
        ChangeNotifierProvider(create: (_) => AdminController()),
      ],
      child: MaterialApp(
        title: 'Students\' Coding Portal',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ),
        ),
        home: const AuthWrapper(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/student-dashboard': (context) => const StudentDashboard(),
          '/staff-dashboard': (context) => const StaffDashboard(),
          '/admin-dashboard': (context) => const AdminDashboard(),
          '/edit-profile': (context) => const EditProfileScreen(),
        },
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    // Use post-frame callback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  Future<void> _initializeApp() async {
    final authController = context.read<AuthController>();
    await authController.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthController>(
      builder: (context, authController, child) {
        print('🔄 AuthWrapper - isLoading: ${authController.isLoading}');
        print('🔄 AuthWrapper - isAuthenticated: ${authController.isAuthenticated}');
        print('🔄 AuthWrapper - currentUser: ${authController.currentUser?.email}');
        print('🔄 AuthWrapper - user role: ${authController.currentUser?.role}');
        
        if (authController.isLoading) {
          print('🔄 Showing loading screen');
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (!authController.isAuthenticated) {
          print('🔄 User not authenticated, showing login screen');
          return const LoginScreen();
        }

        // Route based on user role
        final user = authController.currentUser;
        if (user == null) {
          print('🔄 User is null, showing login screen');
          return const LoginScreen();
        }

        print('🔄 Routing user: ${user.email} (${user.role})');
        print('🔄 User role checks:');
        print('   - isAdmin: ${user.isAdmin}');
        print('   - isStaff: ${user.isStaff}');
        print('   - isStudent: ${user.isStudent}');
        print('   - role string: "${user.role}"');
        
        if (user.isAdmin) {
          print('🔄 Routing to AdminDashboard');
          return const AdminDashboard();
        } else if (user.isStaff) {
          print('🔄 Routing to StaffDashboard');
          return const StaffDashboard();
        } else if (user.isStudent) {
          print('🔄 Routing to StudentDashboard');
          return const StudentDashboard();
        }

        // Default fallback
        print('🔄 No matching role, showing login screen');
        return const LoginScreen();
      },
    );
  }
}
