import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../firebase_options.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Attempts a direct HTTP REST upload to Firebase Storage.
  /// On Windows desktop, this bypasses native C++ progress callback crashes and deadlocks.
  Future<String?> _tryRestUpload({
    required String path,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    HttpClient? client;
    try {
      final bucket = DefaultFirebaseOptions.windows.storageBucket;
      if (bucket == null || bucket.isEmpty) return null;

      final encodedPath = Uri.encodeComponent(path);
      final uri = Uri.parse(
        'https://firebasestorage.googleapis.com/v0/b/$bucket/o?uploadType=media&name=$encodedPath',
      );

      client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
      final request = await client.postUrl(uri);
      request.headers.set('Content-Type', mimeType);

      // Attach Firebase Auth ID token if available
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final idToken = await user.getIdToken();
          if (idToken != null && idToken.isNotEmpty) {
            request.headers.set('Authorization', 'Bearer $idToken');
          }
        }
      } catch (_) {}

      request.add(bytes);
      final response = await request.close().timeout(const Duration(seconds: 10));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final responseBody = await response.transform(utf8.decoder).join();
        final json = jsonDecode(responseBody) as Map<String, dynamic>;
        final downloadTokens = json['downloadTokens']?.toString() ?? '';
        final tokenParam = downloadTokens.isNotEmpty ? '&token=${downloadTokens.split(',').first}' : '';
        client.close();
        return 'https://firebasestorage.googleapis.com/v0/b/$bucket/o/$encodedPath?alt=media$tokenParam';
      }
      client.close();
    } catch (e) {
      debugPrint('REST upload fallback note: $e');
    } finally {
      client?.close();
    }
    return null;
  }

  /// Uploads raw or compressed image bytes to Firebase Storage
  /// Returns the public HTTPS download URL or null on failure/timeout
  Future<String?> uploadMemberImage({
    required String memberId,
    required Uint8List bytes,
    required String folder, // 'profile' or 'signature'
    String mimeType = 'image/jpeg',
  }) async {
    try {
      final ext = mimeType.contains('png') ? 'png' : 'jpg';
      final cleanMemberId = memberId.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
      final path = 'members/$cleanMemberId/$folder.$ext';

      // 1. On Windows desktop, try REST upload first to avoid native C++ progress callback crashes/hangs
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
        final restUrl = await _tryRestUpload(
          path: path,
          bytes: bytes,
          mimeType: mimeType,
        );
        if (restUrl != null && restUrl.isNotEmpty) {
          return restUrl;
        }
      }

      // 2. Attempt standard FirebaseStorage with strict timeouts
      final ref = _storage.ref().child(path);
      final metadata = SettableMetadata(
        contentType: mimeType,
        customMetadata: {
          'uploadedAt': DateTime.now().toIso8601String(),
          'memberId': memberId,
        },
      );

      final uploadTask = await ref.putData(bytes, metadata).timeout(
        const Duration(seconds: 8),
        onTimeout: () => throw TimeoutException('Storage putData timed out after 8s'),
      );
      final downloadUrl = await uploadTask.ref.getDownloadURL().timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw TimeoutException('Storage getDownloadURL timed out after 5s'),
      );
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading member image to Firebase Storage: $e');
      return null;
    }
  }

  /// Converts a Base64 data URL into a Firebase Storage upload and returns the HTTPS URL.
  /// If it is already an HTTPS URL, returns it as-is.
  /// If upload fails, returns null so the caller can fall back safely.
  Future<String?> uploadBase64IfApplicable({
    required String memberId,
    required String base64OrUrl,
    required String folder, // 'profile' or 'signature'
  }) async {
    final str = base64OrUrl.trim();
    if (str.isEmpty || str == 'N/A') return '';
    // If it's already an HTTP(S) URL, it's already hosted on Storage or web
    if (str.startsWith('http://') || str.startsWith('https://')) {
      return str;
    }

    try {
      final raw = str.contains(',') ? str.split(',').last : str;
      final bytes = base64Decode(raw);
      final isPng = folder == 'signature' || str.contains('image/png');
      final mimeType = isPng ? 'image/png' : 'image/jpeg';

      return await uploadMemberImage(
        memberId: memberId,
        bytes: bytes,
        folder: folder,
        mimeType: mimeType,
      ).timeout(
        const Duration(seconds: 12),
        onTimeout: () {
          debugPrint('Storage uploadBase64 timed out for $folder');
          return null;
        },
      );
    } catch (e) {
      debugPrint('Error converting base64 to Storage: $e');
      return null;
    }
  }
}

