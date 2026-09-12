import 'dart:typed_data';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';

class ImageCropScreen extends StatefulWidget {
  final Uint8List imageBytes;
  final String title;
  final double? initialAspectRatio;
  final bool lockAspectRatio;

  const ImageCropScreen({
    super.key,
    required this.imageBytes,
    required this.title,
    this.initialAspectRatio = 1.0,
    this.lockAspectRatio = false,
  });

  static Future<Uint8List?> open(
    BuildContext context, {
    required Uint8List imageBytes,
    required String title,
    double? aspectRatio = 1.0,
    bool lockAspectRatio = false,
  }) {
    return Navigator.of(context).push<Uint8List>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => ImageCropScreen(
          imageBytes: imageBytes,
          title: title,
          initialAspectRatio: aspectRatio,
          lockAspectRatio: lockAspectRatio,
        ),
      ),
    );
  }

  @override
  State<ImageCropScreen> createState() => _ImageCropScreenState();
}

class _ImageCropScreenState extends State<ImageCropScreen> {
  final CropController _cropController = CropController();
  double? _currentAspectRatio;
  bool _isCropping = false;

  @override
  void initState() {
    super.initState();
    _currentAspectRatio = widget.initialAspectRatio;
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0C1B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161226),
        foregroundColor: Colors.white,
        title: Text(
          widget.title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              onPressed: _isCropping
                  ? null
                  : () {
                      setState(() => _isCropping = true);
                      _cropController.crop();
                    },
              icon: _isCropping
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_rounded, size: 18),
              label: const Text('Apply Crop'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Helper instruction banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0xFF1E1A33),
              child: Row(
                children: [
                  Icon(
                    Icons.crop_rotate_rounded,
                    size: 16,
                    color: primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.lockAspectRatio
                          ? 'Pinch and drag corners to frame 1x1 square photo'
                          : 'Pinch and drag the bounding box to frame image',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Crop Widget Area
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Crop(
                    image: widget.imageBytes,
                    controller: _cropController,
                    aspectRatio: _currentAspectRatio,
                    baseColor: const Color(0xFF0F0C1B),
                    maskColor: Colors.black.withValues(alpha: 0.65),
                    radius: 0,
                    cornerDotBuilder: (size, edgeAlignment) => DotControl(
                      color: primaryColor,
                    ),
                    onCropped: (cropped) {
                      setState(() => _isCropping = false);
                      Navigator.of(context).pop(cropped);
                    },
                  ),
                  if (_isCropping)
                    Container(
                      color: Colors.black54,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                primaryColor,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Cropping image...',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Bottom toolbar for aspect ratio selection (if not strictly locked)
            if (!widget.lockAspectRatio)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: const Color(0xFF161226),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildAspectOption('Freeform', null, primaryColor),
                    const SizedBox(width: 10),
                    _buildAspectOption('1:1 Square', 1.0, primaryColor),
                    const SizedBox(width: 10),
                    _buildAspectOption('3:1 Signature', 3.0 / 1.0, primaryColor),
                    const SizedBox(width: 10),
                    _buildAspectOption('4:3', 4.0 / 3.0, primaryColor),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAspectOption(String label, double? ratio, Color primaryColor) {
    final isSelected = _currentAspectRatio == ratio;

    return InkWell(
      onTap: () {
        setState(() {
          _currentAspectRatio = ratio;
        });
        _cropController.aspectRatio = ratio;
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor
              : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : Colors.white70,
          ),
        ),
      ),
    );
  }
}
