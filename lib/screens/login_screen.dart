import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/theme.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback? onAuthenticated;

  const LoginScreen({
    super.key,
    this.onAuthenticated,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _loginIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _rememberCredentials = true;
  bool _obscurePassword = true;
  bool _isLoading = false;

  String? _loginIdError;
  String? _passwordError;

  @override
  void initState() {
    super.initState();
    _checkAutoLoginAndFill();
  }

  Future<void> _checkAutoLoginAndFill() async {
    final authService = AuthService();
    final saved = await authService.getSavedCredentials();
    if (mounted) {
      setState(() {
        _rememberCredentials = saved['rememberMe'] as bool? ?? true;
        if (saved['identifier'] != null && (saved['identifier'] as String).isNotEmpty) {
          _loginIdController.text = saved['identifier'] as String;
        }
        if (saved['password'] != null && (saved['password'] as String).isNotEmpty) {
          _passwordController.text = saved['password'] as String;
        }
      });
    }
  }

  @override
  void dispose() {
    _loginIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleAuthenticate() async {
    FocusScope.of(context).unfocus();

    final identifier = _loginIdController.text.trim();
    final password = _passwordController.text;

    setState(() {
      _loginIdError = identifier.isEmpty ? 'Please enter your Email or Member ID' : null;
      _passwordError = password.isEmpty ? 'Please enter your password' : null;
    });

    if (_loginIdError != null || _passwordError != null) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await AuthService().signInWithIdentifier(
        identifier: identifier,
        password: password,
        rememberMe: _rememberCredentials,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (widget.onAuthenticated != null) {
          widget.onAuthenticated!();
        } else {
          Navigator.of(context).pushReplacementNamed('/portal');
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (e.code == 'user-not-found' || e.code == 'invalid-email') {
            _loginIdError = e.message ?? 'Member ID or Email not registered.';
          } else if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
            _passwordError = 'Invalid password for this account.';
          } else {
            _passwordError = e.message ?? 'Authentication failed. Please check credentials.';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _passwordError = 'Login error: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentViolet = AppTheme.primaryColor;
    final textPrimary = isDark ? const Color(0xFFF5F5FA) : const Color(0xFF0E0E14);
    final textSecondary = isDark ? const Color(0xFF9E9EAF) : const Color(0xFF6E6E82);
    final cardBg = isDark ? const Color(0xFF16161F) : Colors.white;
    final borderColor = isDark ? const Color(0xFF262633) : const Color(0xFFE5E5ED);

    return Scaffold(
      body: Stack(
        children: [
          // Ambient purple ambient glow at top
          Positioned(
            top: -140,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 440,
                height: 440,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      accentViolet.withValues(alpha: isDark ? 0.22 : 0.12),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 1.0],
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Spacer(flex: 2),

                            // Top Brand Logo
                            Center(
                              child: Image.asset(
                                'assets/images/uecfi_portal_app_logo.ico',
                                height: 85,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Image.asset(
                                    'assets/images/uecfi_pmm_logo.png',
                                    height: 85,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) => Icon(
                                      Icons.hub_rounded,
                                      size: 72,
                                      color: accentViolet,
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 18),

                            // DISTRICT 3
                            Text(
                              'DISTRICT 3',
                              style: TextStyle(
                                color: accentViolet,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 2.0,
                              ),
                            ),
                            const SizedBox(height: 6),

                            // Sign In to Portal
                            Text(
                              'Sign In to Portal',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: textPrimary,
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Enter your credentials to access management dashboard
                            Text(
                              'Enter your credentials to access management dashboard',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: textSecondary,
                                fontSize: 14,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 28),

                            // Input fields wrapper
                            Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 440),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: cardBg,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: borderColor,
                                      width: 1.2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.05),
                                        blurRadius: 20,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  padding: const EdgeInsets.all(24.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      // Email or Member ID input
                                      TextField(
                                        controller: _loginIdController,
                                        keyboardType: TextInputType.emailAddress,
                                        textInputAction: TextInputAction.next,
                                        decoration: InputDecoration(
                                          labelText: 'Email or Member ID',
                                          hintText: 'e.g. pastor@uecfi.org or 00001',
                                          prefixIcon: const Icon(Icons.person_outline_rounded),
                                          errorText: _loginIdError,
                                        ),
                                        onChanged: (val) {
                                          if (_loginIdError != null) {
                                            setState(() => _loginIdError = null);
                                          }
                                        },
                                      ),
                                      const SizedBox(height: 18),

                                      // Password input with show/hide
                                      TextField(
                                        controller: _passwordController,
                                        obscureText: _obscurePassword,
                                        textInputAction: TextInputAction.done,
                                        onSubmitted: (_) => _handleAuthenticate(),
                                        decoration: InputDecoration(
                                          labelText: 'Password',
                                          hintText: 'Enter your password',
                                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                                          errorText: _passwordError,
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              _obscurePassword
                                                  ? Icons.visibility_off_outlined
                                                  : Icons.visibility_outlined,
                                              size: 20,
                                            ),
                                            tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                                            onPressed: () {
                                              setState(() {
                                                _obscurePassword = !_obscurePassword;
                                              });
                                            },
                                          ),
                                        ),
                                        onChanged: (val) {
                                          if (_passwordError != null) {
                                            setState(() => _passwordError = null);
                                          }
                                        },
                                      ),
                                      const SizedBox(height: 14),

                                      // Remember Credentials Checkbox
                                      InkWell(
                                        borderRadius: BorderRadius.circular(8),
                                        onTap: () {
                                          setState(() {
                                            _rememberCredentials = !_rememberCredentials;
                                          });
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              SizedBox(
                                                width: 22,
                                                height: 22,
                                                child: Checkbox(
                                                  value: _rememberCredentials,
                                                  activeColor: accentViolet,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(5),
                                                  ),
                                                  onChanged: (val) {
                                                    setState(() {
                                                      _rememberCredentials = val ?? true;
                                                    });
                                                  },
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Text(
                                                'Remember Credentials',
                                                style: TextStyle(
                                                  color: textSecondary,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 22),

                                      // AUTHENTICATE Button
                                      SizedBox(
                                        height: 50,
                                        child: ElevatedButton(
                                          onPressed: _isLoading ? null : _handleAuthenticate,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: accentViolet,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(14),
                                            ),
                                            elevation: 0,
                                          ),
                                          child: _isLoading
                                              ? const SizedBox(
                                                  width: 22,
                                                  height: 22,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2.2,
                                                    color: Colors.white,
                                                  ),
                                                )
                                              : const Text(
                                                  'AUTHENTICATE',
                                                  style: TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.bold,
                                                    letterSpacing: 1.0,
                                                  ),
                                                ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            const Spacer(flex: 3),

                            // Pinned Footer at bottom
                            Padding(
                              padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Develop by',
                                    style: TextStyle(
                                      color: textSecondary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Image.asset(
                                    'assets/images/devchristian_mark.png',
                                    height: 24,
                                    fit: BoxFit.contain,
                                    color: isDark ? Colors.white : null,
                                    errorBuilder: (context, error, stackTrace) => Text(
                                      'devchristian',
                                      style: TextStyle(
                                        color: textPrimary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
