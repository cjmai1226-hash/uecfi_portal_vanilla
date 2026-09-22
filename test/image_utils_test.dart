import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:uecfi_portal_vanilla/utils/image_utils.dart';

void main() {
  test('ImageUtils resizes large image and produces small JPEG', () async {
    // Create a 2000x2000 test image in memory
    final testImage = img.Image(width: 2000, height: 2000);
    for (int y = 0; y < 2000; y++) {
      for (int x = 0; x < 2000; x++) {
        testImage.setPixelRgb(x, y, (x * y) % 255, (x + y) % 255, (x ^ y) % 255);
      }
    }
    final rawJpg = img.encodeJpg(testImage, quality: 95);
    expect(rawJpg.length, greaterThan(300 * 1024)); // > 300 KB raw

    final compressed = await ImageUtils.compressProfilePhoto(rawJpg, targetDimension: 512);

    expect(compressed.length, lessThanOrEqualTo(ImageUtils.maxPhotoBytes));
    final decoded = img.decodeImage(compressed);
    expect(decoded, isNotNull);
    expect(decoded!.width, lessThanOrEqualTo(512));
    expect(decoded.height, lessThanOrEqualTo(512));

    final dataUrl = ImageUtils.toDataUrl(compressed);
    expect(dataUrl.startsWith('data:image/jpeg;base64,'), isTrue);
    final size = ImageUtils.estimateBase64SizeBytes(dataUrl);
    expect(size, lessThan(ImageUtils.maxPhotoBytes + 1000));
  });
}
