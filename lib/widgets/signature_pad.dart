import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/image_utils.dart';
import 'image_crop_screen.dart';

class SignaturePadController {
  _SignaturePadState? _state;

  void _attach(_SignaturePadState state) {
    _state = state;
  }

  void _detach() {
    _state = null;
  }

  void clear() {
    _state?.clear();
  }

  bool get isEmpty => _state?.isEmpty ?? true;

  bool get isNotEmpty => !isEmpty;

  Future<Uint8List?> toPngBytes() async {
    return _state?.exportPngBytes();
  }

  Future<String?> toBase64Png() async {
    final bytes = await toPngBytes();
    if (bytes == null || bytes.isEmpty) return null;
    return 'data:image/png;base64,${base64Encode(bytes)}';
  }
}

class SignaturePad extends StatefulWidget {
  final SignaturePadController? controller;
  final double height;
  final Color strokeColor;
  final double strokeWidth;
  final VoidCallback? onDrawStart;
  final VoidCallback? onDrawEnd;
  final ValueChanged<bool>? onEmptyChanged;

  const SignaturePad({
    super.key,
    this.controller,
    this.height = 160,
    this.strokeColor = const Color(0xFF1E1E2C),
    this.strokeWidth = 2.5,
    this.onDrawStart,
    this.onDrawEnd,
    this.onEmptyChanged,
  });

  @override
  State<SignaturePad> createState() => _SignaturePadState();
}

class _SignaturePadState extends State<SignaturePad> {
  final GlobalKey _boundaryKey = GlobalKey();
  final List<List<Offset>> _strokes = [];
  List<Offset> _currentStroke = [];

  @override
  void initState() {
    super.initState();
    widget.controller?._attach(this);
  }

  @override
  void didUpdateWidget(SignaturePad oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._detach();
      widget.controller?._attach(this);
    }
  }

  @override
  void dispose() {
    widget.controller?._detach();
    super.dispose();
  }

  bool get isEmpty => _strokes.isEmpty && _currentStroke.isEmpty;

  void clear() {
    setState(() {
      _strokes.clear();
      _currentStroke.clear();
    });
    widget.onEmptyChanged?.call(true);
  }

  Future<Uint8List?> exportPngBytes() async {
    if (isEmpty) return null;
    try {
      final boundary = _boundaryKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final strokeColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final borderColor = isDark ? const Color(0xFF262633) : const Color(0xFFE5E5ED);

    final canvasBox = RepaintBoundary(
      key: _boundaryKey,
      child: Container(
        height: widget.height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF16161F) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: borderColor,
            width: 1.2,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              // Signature baseline guide
              Positioned(
                bottom: 40,
                left: 24,
                right: 24,
                child: Row(
                  children: [
                    Text(
                      '✕',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.25)
                            : Colors.black.withValues(alpha: 0.25),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        height: 1,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.15)
                            : Colors.black.withValues(alpha: 0.12),
                      ),
                    ),
                  ],
                ),
              ),

              // Prompt when empty
              if (isEmpty)
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.draw_rounded,
                        size: 32,
                        color: (isDark ? Colors.white54 : Colors.black45)
                            .withValues(alpha: 0.4),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sign here using your finger or stylus',
                        style: TextStyle(
                          fontSize: 13,
                          color: (isDark ? Colors.white54 : Colors.black45)
                              .withValues(alpha: 0.6),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),

              // Drawing Canvas with Pan Gestures
              GestureDetector(
                onPanStart: (details) {
                  final box = context.findRenderObject() as RenderBox?;
                  if (box == null) return;
                  final local = details.localPosition;
                  setState(() {
                    _currentStroke = [local];
                    _strokes.add(_currentStroke);
                  });
                  widget.onDrawStart?.call();
                  widget.onEmptyChanged?.call(false);
                },
                onPanUpdate: (details) {
                  final local = details.localPosition;
                  setState(() {
                    _currentStroke.add(local);
                  });
                },
                onPanEnd: (details) {
                  widget.onDrawEnd?.call();
                  widget.onEmptyChanged?.call(isEmpty);
                },
                child: CustomPaint(
                  painter: _SignaturePainter(
                    strokes: _strokes,
                    strokeColor: strokeColor,
                    strokeWidth: widget.strokeWidth,
                  ),
                  size: Size.infinite,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (widget.height == double.infinity) {
      return canvasBox;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        canvasBox,
      ],
    );
  }
}

class FullscreenSignatureScreen extends StatefulWidget {
  final Uint8List? initialSignatureBytes;

  const FullscreenSignatureScreen({super.key, this.initialSignatureBytes});

  static Future<Uint8List?> open(
    BuildContext context, {
    Uint8List? initialSignatureBytes,
  }) {
    return Navigator.of(context).push<Uint8List>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => FullscreenSignatureScreen(
          initialSignatureBytes: initialSignatureBytes,
        ),
      ),
    );
  }

  @override
  State<FullscreenSignatureScreen> createState() =>
      _FullscreenSignatureScreenState();
}

class _FullscreenSignatureScreenState extends State<FullscreenSignatureScreen> {
  final SignaturePadController _controller = SignaturePadController();
  bool _hasDrawn = false;
  bool _isSaving = false;
  bool _isLandscape = true;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  void _toggleOrientation() {
    setState(() {
      _isLandscape = !_isLandscape;
      if (_isLandscape) {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      } else {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F0C1B) : const Color(0xFFF8F9FC),
      appBar: AppBar(
        toolbarHeight: 48,
        title: const Text(
          'Draw Signature (Landscape)',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.screen_rotation_rounded, size: 20),
            tooltip: _isLandscape ? 'Switch to Portrait' : 'Switch to Landscape',
            onPressed: _toggleOrientation,
          ),
          IconButton(
            icon: const Icon(Icons.photo_library_rounded, size: 20),
            tooltip: 'Upload Photo of Signature',
            onPressed: () async {
              final nav = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              try {
                final picker = ImagePicker();
                final picked = await picker.pickImage(
                  source: ImageSource.gallery,
                  maxWidth: 1600,
                  maxHeight: 1600,
                  imageQuality: 95,
                );
                if (!mounted || picked == null) return;
                final raw = await picked.readAsBytes();
                if (!mounted) return;
                final input = await ImageUtils.prepareForCropping(raw);
                if (!mounted) return;
                final cropped = await ImageCropScreen.open(
                  this.context,
                  imageBytes: input,
                  title: 'Crop Signature',
                  aspectRatio: 3.0,
                  lockAspectRatio: false,
                );
                if (!mounted || cropped == null) return;
                final optimized = await ImageUtils.compressSignature(cropped);
                nav.pop(optimized);
              } catch (e) {
                if (!mounted) return;
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Failed to pick photo: $e'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
          ),
          TextButton.icon(
            onPressed: () {
              _controller.clear();
              setState(() => _hasDrawn = false);
            },
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Clear'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.redAccent,
            ),
          ),
          const SizedBox(width: 4),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              onPressed: _hasDrawn && !_isSaving
                  ? () async {
                      final navigator = Navigator.of(context);
                      setState(() => _isSaving = true);
                      final bytes = await _controller.toPngBytes();
                      if (mounted) {
                        navigator.pop(bytes);
                      }
                    }
                  : null,
              icon: _isSaving
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_rounded, size: 18),
              label: const Text('Apply Signature'),
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
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            children: [
              Expanded(
                child: SignaturePad(
                  controller: _controller,
                  height: double.infinity,
                  strokeWidth: 3.2,
                  onEmptyChanged: (isEmpty) {
                    setState(() {
                      _hasDrawn = !isEmpty;
                    });
                  },
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.touch_app_rounded,
                    size: 16,
                    color: isDark ? Colors.white54 : Colors.black45,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Draw your official signature comfortably on the landscape pad with your finger or stylus',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isDark ? Colors.white54 : Colors.black45,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SignaturePainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final Color strokeColor;
  final double strokeWidth;

  _SignaturePainter({
    required this.strokes,
    required this.strokeColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = strokeColor
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      if (stroke.isEmpty) continue;
      if (stroke.length == 1) {
        canvas.drawCircle(
            stroke.first, strokeWidth / 2, paint..style = PaintingStyle.fill);
        paint.style = PaintingStyle.stroke;
        continue;
      }

      final path = Path();
      path.moveTo(stroke.first.dx, stroke.first.dy);

      for (int i = 1; i < stroke.length; i++) {
        final p0 = stroke[i - 1];
        final p1 = stroke[i];
        final midX = (p0.dx + p1.dx) / 2;
        final midY = (p0.dy + p1.dy) / 2;
        path.quadraticBezierTo(p0.dx, p0.dy, midX, midY);
      }

      path.lineTo(stroke.last.dx, stroke.last.dy);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) {
    return true;
  }
}
