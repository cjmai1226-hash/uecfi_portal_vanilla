import 'dart:convert';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Uploads raw or compressed image bytes to Firebase Storage
  /// Returns the public HTTPS download URL
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

      final ref = _storage.ref().child(path);
      final metadata = SettableMetadata(
        contentType: mimeType,
        customMetadata: {
          'uploadedAt': DateTime.now().toIso8601String(),
          'memberId': memberId,
        },
      );

      final uploadTask = await ref.putData(bytes, metadata);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading member image to Firebase Storage: $e');
      return null;
    }
  }

  /// Converts a Base64 data URL into a Firebase Storage upload and returns the HTTPS URL.
  /// If it is already an HTTPS URL, returns it as-is.
  /// If upload fails, returns null.
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
      );
    } catch (e) {
      debugPrint('Error converting base64 to Storage: $e');
      return null;
    }
  }
}
