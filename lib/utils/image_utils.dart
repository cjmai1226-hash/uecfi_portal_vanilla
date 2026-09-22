import 'dart:convert';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Utility for optimizing, resizing, and compressing member profile photos
/// and signatures. Ensures all images uploaded as base64 into Firestore stay
/// well below Firestore's 1 MiB document size limit (typically 30-70 KB).
class ImageUtils {
  /// Maximum allowed byte size for a photo before base64 encoding (200 KB).
  /// A 200 KB image results in ~266 KB of Base64, well under Firestore's 1048 KB limit.
  static const int maxPhotoBytes = 200 * 1024;

  /// Downscale large raw photos before feeding them to the cropper so the
  /// cropper doesn't lag or run out of memory with 10-20 MB camera files.
  static Future<Uint8List> prepareForCropping(
    Uint8List rawBytes, {
    int maxDimension = 1600,
  }) async {
    try {
      return await Isolate.run(() {
        final original = img.decodeImage(rawBytes);
        if (original == null) return rawBytes;

        if (original.width <= maxDimension && original.height <= maxDimension) {
          return rawBytes;
        }

        final resized = img.copyResize(
          original,
          width: original.width >= original.height ? maxDimension : null,
          height: original.height > original.width ? maxDimension : null,
          interpolation: img.Interpolation.linear,
        );

        return Uint8List.fromList(img.encodeJpg(resized, quality: 90));
      });
    } catch (e) {
      debugPrint('prepareForCropping error: $e');
      return rawBytes;
    }
  }

  /// Compresses and resizes a cropped 1x1 profile photo down to a maximum of
  /// [targetDimension] x [targetDimension] pixels (default 512x512) and encodes as JPEG.
  /// Resulting file is typically 30 KB - 60 KB (~40-80 KB in Base64).
  static Future<Uint8List> compressProfilePhoto(
    Uint8List inputBytes, {
    int targetDimension = 512,
    int initialQuality = 82,
  }) async {
    try {
      return await Isolate.run(() {
        final image = img.decodeImage(inputBytes);
        if (image == null) return inputBytes;

        // Resize to 1x1 square avatar dimensions
        img.Image resized = image;
        if (image.width > targetDimension || image.height > targetDimension) {
          resized = img.copyResize(
            image,
            width: targetDimension,
            height: targetDimension,
            interpolation: img.Interpolation.linear,
          );
        }

        int currentQuality = initialQuality;
        List<int> encoded = img.encodeJpg(resized, quality: currentQuality);

        // If for any reason the image is still above the limit, lower quality/size
        while (encoded.length > maxPhotoBytes && currentQuality > 40) {
          currentQuality -= 12;
          encoded = img.encodeJpg(resized, quality: currentQuality);
        }

        // If still somehow large, shrink dimension
        if (encoded.length > maxPhotoBytes) {
          final smaller = img.copyResize(
            resized,
            width: 360,
            height: 360,
            interpolation: img.Interpolation.linear,
          );
          encoded = img.encodeJpg(smaller, quality: 70);
        }

        return Uint8List.fromList(encoded);
      });
    } catch (e) {
      debugPrint('compressProfilePhoto error: $e');
      return inputBytes;
    }
  }

  /// Compresses a signature image to fit within [maxWidth] x [maxHeight]
  /// and maintains transparent PNG format or crisp JPEG.
  static Future<Uint8List> compressSignature(
    Uint8List inputBytes, {
    int maxWidth = 600,
    int maxHeight = 300,
  }) async {
    try {
      return await Isolate.run(() {
        final image = img.decodeImage(inputBytes);
        if (image == null) return inputBytes;

        img.Image resized = image;
        if (image.width > maxWidth || image.height > maxHeight) {
          resized = img.copyResize(
            image,
            width: image.width > image.height ? maxWidth : null,
            height: image.height >= image.width ? maxHeight : null,
            interpolation: img.Interpolation.linear,
          );
        }

        // Use PNG with level 6 compression to preserve transparency if available
        final encoded = img.encodePng(resized, level: 6);
        return Uint8List.fromList(encoded);
      });
    } catch (e) {
      debugPrint('compressSignature error: $e');
      return inputBytes;
    }
  }

  /// Formats raw bytes as a standard data URL base64 string
  static String toDataUrl(Uint8List bytes, {String mimeType = 'image/jpeg'}) {
    return 'data:$mimeType;base64,${base64Encode(bytes)}';
  }

  /// Estimates the byte size of a data URL or Base64 string
  static int estimateBase64SizeBytes(String base64Str) {
    if (base64Str.isEmpty) return 0;
    final clean = base64Str.contains(',') ? base64Str.split(',').last : base64Str;
    final padding = clean.endsWith('==') ? 2 : (clean.endsWith('=') ? 1 : 0);
    return ((clean.length * 3) ~/ 4) - padding;
  }
}
