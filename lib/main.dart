import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/main_navigation_screen.dart';
import 'services/auth_service.dart';
import 'theme/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeService.instance,
      builder: (context, themeMode, child) {
        return MaterialApp(
          title: 'UECFI Portal',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          initialRoute: '/',
          routes: {
            '/': (context) => const AuthGate(),
            '/login': (context) => const LoginScreen(),
            '/portal': (context) => const MainNavigationScreen(),
          },
        );
      },
    );
  }
}

/// AuthGate checks if an authenticated session exists or can be restored automatically.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _isChecking = true;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    try {
      final isAuthed = await AuthService().checkAutoLogin();
      if (mounted) {
        setState(() {
          _isAuthenticated = isAuthed;
          _isChecking = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isAuthenticated = false;
          _isChecking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final primaryColor = Theme.of(context).colorScheme.primary;

      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF0E0E14) : const Color(0xFFF9F9FC),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primaryColor.withValues(alpha: 0.12),
                ),
                child: Center(
                  child: Icon(
                    Icons.account_balance_rounded,
                    size: 36,
                    color: primaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return _isAuthenticated ? const MainNavigationScreen() : const LoginScreen();
  }
}
