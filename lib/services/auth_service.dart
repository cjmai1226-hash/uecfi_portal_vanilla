import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _keyIsLoggedIn = 'auth_is_logged_in';
  static const String _keyIdentifier = 'auth_saved_identifier';
  static const String _keyPassword = 'auth_saved_password';
  static const String _keyRememberMe = 'auth_remember_me';

  /// Current authenticated user
  User? get currentUser => _auth.currentUser;

  /// Stream of authentication state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Check if user has an active session or can auto-login from saved session
  Future<bool> checkAutoLogin() async {
    // 1. Direct Firebase Auth session check
    if (_auth.currentUser != null) {
      return true;
    }

    // 2. Check local persistence
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;
      final savedId = prefs.getString(_keyIdentifier) ?? '';
      final savedPassword = prefs.getString(_keyPassword) ?? '';

      if (isLoggedIn && savedId.isNotEmpty && savedPassword.isNotEmpty) {
        debugPrint('Attempting auto-login for saved user: $savedId');
        await signInWithIdentifier(
          identifier: savedId,
          password: savedPassword,
          rememberMe: true,
        );
        return _auth.currentUser != null;
      }
    } catch (e) {
      debugPrint('Auto-login check error: $e');
    }

    return _auth.currentUser != null;
  }

  /// Get saved credentials for pre-filling login form
  Future<Map<String, dynamic>> getSavedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rememberMe = prefs.getBool(_keyRememberMe) ?? true;
      final savedId = prefs.getString(_keyIdentifier) ?? '';
      final savedPassword = prefs.getString(_keyPassword) ?? '';
      return {
        'rememberMe': rememberMe,
        'identifier': savedId,
        'password': rememberMe ? savedPassword : '',
      };
    } catch (_) {
      return {
        'rememberMe': true,
        'identifier': '',
        'password': '',
      };
    }
  }

  /// Logs in using either an Email address or Member ID
  Future<UserCredential> signInWithIdentifier({
    required String identifier,
    required String password,
    bool rememberMe = true,
  }) async {
    String email = identifier.trim();

    // 1. If it's a Member ID (no '@'), resolve the associated email from Firestore
    if (!email.contains('@')) {
      final doc = await _firestore.collection('members').doc(email).get();
      if (doc.exists && doc.data()?['email'] != null) {
        email = doc.data()!['email'];
      } else {
        // Query by memberId field in members collection
        final query = await _firestore
            .collection('members')
            .where('memberId', isEqualTo: email)
            .limit(1)
            .get();
        if (query.docs.isNotEmpty && query.docs.first.data()['email'] != null) {
          email = query.docs.first.data()['email'];
        } else {
          throw FirebaseAuthException(
            code: 'user-not-found',
            message: 'Member ID "$email" not found or has no registered email.',
          );
        }
      }
    }

    // 2. Authenticate with Firebase Auth
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password.trim(),
    );

    // 3. Save login session locally for persistence across app restarts
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyIsLoggedIn, true);
      await prefs.setBool(_keyRememberMe, rememberMe);
      await prefs.setString(_keyIdentifier, identifier.trim());
      if (rememberMe) {
        await prefs.setString(_keyPassword, password.trim());
      } else {
        await prefs.remove(_keyPassword);
      }
    } catch (e) {
      debugPrint('Error saving login preferences: $e');
    }

    return credential;
  }

  /// Sign out from Firebase and clear saved session
  Future<void> signOut() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyIsLoggedIn, false);
      await prefs.remove(_keyPassword);
    } catch (e) {
      debugPrint('Error clearing session preferences: $e');
    }
    await _auth.signOut();
  }
}
