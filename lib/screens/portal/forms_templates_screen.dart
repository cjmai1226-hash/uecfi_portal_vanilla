import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FormDocument {
  final String title;
  final String fileName;
  final String assetPath;
  final String size;

  const FormDocument({
    required this.title,
    required this.fileName,
    required this.assetPath,
    required this.size,
  });
}

class FormsTemplatesScreen extends StatefulWidget {
  const FormsTemplatesScreen({super.key});

  @override
  State<FormsTemplatesScreen> createState() => _FormsTemplatesScreenState();
}

class _FormsTemplatesScreenState extends State<FormsTemplatesScreen> {
  final Set<String> _downloadingFiles = {};

  static const List<FormDocument> forms = [
    FormDocument(
      title: 'Member Application Form',
      fileName: 'Member Application Form.pdf',
      assetPath: 'assets/forms/Member Application Form.pdf',
      size: '109 KB',
    ),
    FormDocument(
      title: 'Center Application Form',
      fileName: 'Center Application Form.pdf',
      assetPath: 'assets/forms/Center Application Form.pdf',
      size: '306 KB',
    ),
    FormDocument(
      title: 'Foreign Center Form',
      fileName: 'Foreign Center Form.pdf',
      assetPath: 'assets/forms/Foreign Center Form.pdf',
      size: '193 KB',
    ),
  ];

  Future<void> _downloadForm(FormDocument form) async {
    if (_downloadingFiles.contains(form.fileName)) return;

    setState(() {
      _downloadingFiles.add(form.fileName);
    });

    try {
      // 1. Load PDF bytes from asset
      final byteData = await rootBundle.load(form.assetPath);
      final bytes = byteData.buffer.asUint8List();

      String? savedLocation;

      // 2. On Android devices, attempt direct save to the public Downloads folder
      if (!kIsWeb && Platform.isAndroid) {
        try {
          final downloadDir = Directory('/storage/emulated/0/Download');
          if (downloadDir.existsSync()) {
            final targetFile = File('${downloadDir.path}/${form.fileName}');
            await targetFile.writeAsBytes(bytes);
            savedLocation = targetFile.path;
          }
        } catch (_) {
          // Direct file access restricted; fall back to FilePicker
        }
      }

      // 3. If not saved directly (or on Desktop/Web/iOS/SAF fallback), use FilePicker.platform.saveFile
      if (savedLocation == null) {
        final selectedPath = await FilePicker.platform.saveFile(
          dialogTitle: 'Save ${form.fileName}',
          fileName: form.fileName,
          type: FileType.custom,
          allowedExtensions: ['pdf'],
          bytes: bytes,
        );

        if (selectedPath != null) {
          if (!kIsWeb) {
            final file = File(selectedPath);
            if (!file.existsSync() || await file.length() == 0) {
              await file.writeAsBytes(bytes);
            }
          }
          savedLocation = selectedPath;
        }
      }

      if (mounted) {
        setState(() {
          _downloadingFiles.remove(form.fileName);
        });

        if (savedLocation != null) {
          _showDownloadSuccessDialog(form, savedLocation);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _downloadingFiles.remove(form.fileName);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(child: Text('Failed to download ${form.fileName}: $e')),
              ],
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  void _showDownloadSuccessDialog(FormDocument form, String path) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final cardBg = isDark ? const Color(0xFF1E1E2A) : Colors.white;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF00C853).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF00C853),
                size: 26,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Download Complete',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              form.fileName,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'The form has been successfully saved to your phone storage:',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white70 : Colors.black87,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.black26 : const Color(0xFFF2F2F7),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark ? Colors.white12 : Colors.black12,
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.folder_open_rounded, size: 18, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      path,
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        color: isDark ? Colors.white60 : Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final textPrimary = isDark ? const Color(0xFFF5F5FA) : const Color(0xFF0E0E14);
    final textSecondary = isDark ? const Color(0xFF9E9EAF) : const Color(0xFF6E6E82);
    final cardBg = isDark ? const Color(0xFF16161F) : Colors.white;
    final borderColor = isDark ? const Color(0xFF262633) : const Color(0xFFE5E5ED);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Forms and Templates',
          style: TextStyle(
            color: textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
        scrolledUnderElevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          color: textPrimary,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Hero Banner Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: borderColor, width: 1.1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'OFFICIAL ARCHIVES',
                        style: TextStyle(
                          color: primaryColor,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.4,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${forms.length} Available',
                          style: TextStyle(
                            color: primaryColor,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Forms & Templates',
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Download official UECFI District 3 registration, center affiliation, and foreign fellowship PDF forms directly to your phone for offline filling and filing.',
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 13.5,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Tip Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: isDark ? 0.12 : 0.07),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: primaryColor.withValues(alpha: 0.25),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.touch_app_rounded, size: 20, color: primaryColor),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Press any form below to download it directly to your phone.',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Forms List
            ...forms.map((form) {
              final isDownloading = _downloadingFiles.contains(form.fileName);

              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor, width: 1.1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => _downloadForm(form),
                      splashColor: primaryColor.withValues(alpha: 0.12),
                      hoverColor: primaryColor.withValues(alpha: 0.05),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // PDF Icon Box
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: primaryColor.withValues(
                                  alpha: isDark ? 0.22 : 0.1,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.picture_as_pdf_rounded,
                                  color: primaryColor,
                                  size: 24,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),

                            // Document Info: Form Name & Size
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    form.title,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    form.size,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w500,
                                      color: textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Download Action Button
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isDownloading
                                    ? primaryColor.withValues(alpha: 0.15)
                                    : primaryColor,
                                shape: BoxShape.circle,
                              ),
                              child: isDownloading
                                  ? Center(
                                      child: SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.2,
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            primaryColor,
                                          ),
                                        ),
                                      ),
                                    )
                                  : const Icon(
                                      Icons.file_download_outlined,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
