import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/member.dart';
import '../../models/post.dart';
import '../../services/firestore_service.dart';
import '../../widgets/formatted_post_text.dart';

class CreatePostScreen extends StatefulWidget {
  final Post? postToEdit;

  const CreatePostScreen({
    super.key,
    this.postToEdit,
  });

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  final FocusNode _contentFocusNode = FocusNode();

  bool _isLoading = false;
  bool _showPreview = false;

  @override
  void initState() {
    super.initState();
    final edit = widget.postToEdit;
    _titleController = TextEditingController(text: edit?.title ?? '');
    _contentController = TextEditingController(text: edit?.content ?? '');

    _contentController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _contentFocusNode.dispose();
    super.dispose();
  }

  void _formatBold() {
    final text = _contentController.text;
    final selection = _contentController.selection;

    if (selection.isValid && !selection.isCollapsed) {
      final selectedText = text.substring(selection.start, selection.end);
      final newText = text.replaceRange(selection.start, selection.end, '**$selectedText**');
      _contentController.value = TextEditingValue(
        text: newText,
        selection: TextSelection(
          baseOffset: selection.start + 2,
          extentOffset: selection.end + 2,
        ),
      );
    } else {
      final cursor = selection.isValid ? selection.start : text.length;
      const placeholder = 'bold text';
      final newText = text.replaceRange(cursor, cursor, '**$placeholder**');
      _contentController.value = TextEditingValue(
        text: newText,
        selection: TextSelection(
          baseOffset: cursor + 2,
          extentOffset: cursor + 2 + placeholder.length,
        ),
      );
    }
    _contentFocusNode.requestFocus();
  }

  void _formatItalic() {
    final text = _contentController.text;
    final selection = _contentController.selection;

    if (selection.isValid && !selection.isCollapsed) {
      final selectedText = text.substring(selection.start, selection.end);
      final newText = text.replaceRange(selection.start, selection.end, '*$selectedText*');
      _contentController.value = TextEditingValue(
        text: newText,
        selection: TextSelection(
          baseOffset: selection.start + 1,
          extentOffset: selection.end + 1,
        ),
      );
    } else {
      final cursor = selection.isValid ? selection.start : text.length;
      const placeholder = 'italic text';
      final newText = text.replaceRange(cursor, cursor, '*$placeholder*');
      _contentController.value = TextEditingValue(
        text: newText,
        selection: TextSelection(
          baseOffset: cursor + 1,
          extentOffset: cursor + 1 + placeholder.length,
        ),
      );
    }
    _contentFocusNode.requestFocus();
  }

  void _formatBullet() {
    final text = _contentController.text;
    final selection = _contentController.selection;
    final cursor = selection.isValid ? selection.start : text.length;

    String insertText = '• ';
    if (cursor > 0 && text[cursor - 1] != '\n') {
      insertText = '\n• ';
    }

    final newText = text.replaceRange(
      cursor,
      selection.isValid ? selection.end : cursor,
      insertText,
    );
    _contentController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: cursor + insertText.length),
    );
    _contentFocusNode.requestFocus();
  }

  void _formatNumbered() {
    final text = _contentController.text;
    final selection = _contentController.selection;
    final cursor = selection.isValid ? selection.start : text.length;

    int nextNumber = 1;
    if (cursor > 0) {
      final textBefore = text.substring(0, cursor);
      final lines = textBefore.split('\n');
      if (lines.isNotEmpty) {
        final lastLine = lines.last.trim();
        final match = RegExp(r'^(\d+)\.').firstMatch(lastLine);
        if (match != null) {
          nextNumber = (int.tryParse(match.group(1)!) ?? 0) + 1;
        }
      }
    }

    String insertText = '$nextNumber. ';
    if (cursor > 0 && text[cursor - 1] != '\n') {
      insertText = '\n$nextNumber. ';
    }

    final newText = text.replaceRange(
      cursor,
      selection.isValid ? selection.end : cursor,
      insertText,
    );
    _contentController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: cursor + insertText.length),
    );
    _contentFocusNode.requestFocus();
  }

  Future<void> _handleSubmit({
    required String authorId,
    required String authorName,
    required String authorRole,
    required String authorCenter,
    required String authorProfileUrl,
  }) async {
    if (!_formKey.currentState!.validate()) return;
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter post content before publishing.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final currentMember = await _firestoreService.getCurrentMember();
    if (currentMember != null && !currentMember.canCreateDistrictPosts) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Only District Admins and Administrators are permitted to make posts.'),
            backgroundColor: Color(0xFFFF2A55),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final isEditing = widget.postToEdit != null;
      final title = _titleController.text.trim().isNotEmpty
          ? _titleController.text.trim()
          : (_contentController.text.trim().length > 60
              ? '${_contentController.text.trim().substring(0, 57)}...'
              : _contentController.text.trim());

      if (isEditing) {
        final updatedPost = widget.postToEdit!.copyWith(
          title: title,
          content: _contentController.text.trim(),
          category: widget.postToEdit?.category ?? '',
          isPinned: false,
        );

        await _firestoreService.updatePost(updatedPost);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('District post updated successfully!'),
              backgroundColor: Color(0xFF00C853),
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.of(context).pop();
        }
      } else {
        final newPost = Post(
          id: '',
          authorId: authorId,
          authorName: authorName,
          authorRole: authorRole,
          authorCenter: authorCenter,
          authorProfileUrl: authorProfileUrl,
          title: title,
          content: _contentController.text.trim(),
          category: '',
          createdAt: DateTime.now().toIso8601String(),
          isPinned: false,
        );

        await _firestoreService.createPost(newPost);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('District post published successfully!'),
              backgroundColor: Color(0xFF00C853),
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save post: $e'),
            backgroundColor: const Color(0xFFFF2A55),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final textPrimary = isDark ? const Color(0xFFF5F5FA) : const Color(0xFF0E0E14);
    final textSecondary = isDark ? const Color(0xFF9E9EAF) : const Color(0xFF6E6E82);
    final cardBg = isDark ? const Color(0xFF16161F) : Colors.white;
    final borderColor = isDark ? const Color(0xFF262633) : const Color(0xFFE5E5ED);
    final isEditing = widget.postToEdit != null;

    final currentUser = FirebaseAuth.instance.currentUser;

    return StreamBuilder<Member?>(
      stream: _firestoreService.getCurrentMemberStream(),
      builder: (context, snapshot) {
        final currentMember = snapshot.data;

        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(
              title: Text(isEditing ? 'Edit District Post' : 'Create District Post'),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final hasAccess = currentMember != null && currentMember.canCreateDistrictPosts;
        if (!hasAccess) {
          return Scaffold(
            appBar: AppBar(
              title: Text(
                isEditing ? 'Edit District Post' : 'Create District Post',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                color: textPrimary,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF2A55).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lock_person_rounded,
                        size: 48,
                        color: Color(0xFFFF2A55),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Access Restricted',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Only District Admins and Administrators are permitted to create or edit district posts.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Return to Portal'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // Resolve author attribution automatically from authenticated session
        final String authorName = isEditing
            ? widget.postToEdit!.authorName
            : (currentMember.fullName.trim().isNotEmpty
                ? currentMember.fullName.trim()
                : (currentUser?.displayName != null && currentUser!.displayName!.trim().isNotEmpty
                    ? currentUser.displayName!.trim()
                    : (currentUser?.email != null && currentUser!.email!.isNotEmpty
                        ? currentUser.email!.split('@').first
                        : 'District Official')));

        final String authorRole = isEditing
            ? widget.postToEdit!.authorRole
            : (currentMember.primaryPosition.isNotEmpty
                ? currentMember.primaryPosition
                : (currentMember.memberType.isNotEmpty
                    ? currentMember.memberType
                    : 'District Leader'));

        final String authorCenter = isEditing
            ? widget.postToEdit!.authorCenter
            : (currentMember.center.isNotEmpty
                ? currentMember.center
                : 'Central District 3');

        final String authorProfileUrl = isEditing
            ? widget.postToEdit!.authorProfileUrl
            : (currentMember.profileUrl.isNotEmpty
                ? currentMember.profileUrl
                : (currentUser?.photoURL ?? ''));

        final String authorId = isEditing
            ? widget.postToEdit!.authorId
            : (currentMember.id.isNotEmpty
                ? currentMember.id
                : (currentMember.memberId.isNotEmpty
                    ? currentMember.memberId
                    : (currentUser?.uid ?? 'admin')));

        final initial = authorName.isNotEmpty ? authorName[0].toUpperCase() : 'P';

        return Scaffold(
          appBar: AppBar(
            title: Text(
              isEditing ? 'Edit District Post' : 'Create District Post',
              style: TextStyle(
                color: textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            elevation: 0,
            actions: [
              IconButton(
                tooltip: _showPreview ? 'Edit mode' : 'Preview formatting',
                icon: Icon(
                  _showPreview ? Icons.edit_note_rounded : Icons.visibility_outlined,
                  color: primaryColor,
                ),
                onPressed: () {
                  setState(() {
                    _showPreview = !_showPreview;
                  });
                },
              ),
              Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: Center(
                  child: ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : () => _handleSubmit(
                              authorId: authorId,
                              authorName: authorName,
                              authorRole: authorRole,
                              authorCenter: authorCenter,
                              authorProfileUrl: authorProfileUrl,
                            ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            isEditing ? 'Save' : 'Publish',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ),
            ],
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              children: [
                // Automatically Determined Author Attribution Card
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: isDark ? 0.12 : 0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: primaryColor.withValues(alpha: isDark ? 0.30 : 0.20),
                      width: 1.1,
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 19,
                        backgroundColor: primaryColor.withValues(alpha: 0.18),
                        backgroundImage: authorProfileUrl.isNotEmpty
                            ? (authorProfileUrl.startsWith('data:')
                                ? MemoryImage(base64Decode(authorProfileUrl.split(',').last))
                                : NetworkImage(authorProfileUrl) as ImageProvider)
                            : null,
                        child: authorProfileUrl.isEmpty
                            ? Text(
                                initial,
                                style: TextStyle(
                                  color: primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Posting as ',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Flexible(
                                  child: Text(
                                    authorName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.bold,
                                      color: textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$authorRole • $authorCenter',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Verified',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // Post Title Field
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Post Title / Subject',
                    hintText: 'e.g., District Assembly Announcement',
                    hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.6)),
                    filled: true,
                    fillColor: cardBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: primaryColor, width: 1.5),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please provide a title or headline for this post';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Content Editor / Live Preview
                if (_showPreview) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: primaryColor.withValues(alpha: 0.5), width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.visibility_rounded, size: 16, color: primaryColor),
                            const SizedBox(width: 6),
                            Text(
                              'POST PREVIEW',
                              style: TextStyle(
                                color: primaryColor,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _titleController.text.trim().isNotEmpty
                              ? _titleController.text.trim()
                              : 'Untitled Post',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        FormattedPostText(
                          text: _contentController.text.trim().isNotEmpty
                              ? _contentController.text.trim()
                              : 'No content entered yet.',
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // Rich Formatting Toolbar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      children: [
                        _buildFormatBtn(
                          icon: Icons.format_bold_rounded,
                          tooltip: 'Bold (**text**)',
                          onTap: _formatBold,
                          primaryColor: primaryColor,
                        ),
                        _buildFormatBtn(
                          icon: Icons.format_italic_rounded,
                          tooltip: 'Italic (*text*)',
                          onTap: _formatItalic,
                          primaryColor: primaryColor,
                        ),
                        const SizedBox(width: 4),
                        Container(height: 20, width: 1, color: borderColor),
                        const SizedBox(width: 4),
                        _buildFormatBtn(
                          icon: Icons.format_list_bulleted_rounded,
                          tooltip: 'Bullet List (• item)',
                          onTap: _formatBullet,
                          primaryColor: primaryColor,
                        ),
                        _buildFormatBtn(
                          icon: Icons.format_list_numbered_rounded,
                          tooltip: 'Numbered List (1. item)',
                          onTap: _formatNumbered,
                          primaryColor: primaryColor,
                        ),
                        const Spacer(),
                        Text(
                          '${_contentController.text.length} chars',
                          style: TextStyle(fontSize: 11, color: textSecondary),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                  ),

                  // Content Text Area
                  TextFormField(
                    controller: _contentController,
                    focusNode: _contentFocusNode,
                    maxLines: 9,
                    minLines: 6,
                    decoration: InputDecoration(
                      hintText: 'Type your announcement, devotional message, or district update here...\n\nUse the formatting toolbar above for bold, italic, and lists.',
                      hintStyle: TextStyle(
                        color: textSecondary.withValues(alpha: 0.5),
                        fontSize: 13.5,
                      ),
                      filled: true,
                      fillColor: cardBg,
                      border: OutlineInputBorder(
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
                        borderSide: BorderSide(color: primaryColor, width: 1.5),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFormatBtn({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    required Color primaryColor,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Icon(icon, size: 20, color: primaryColor),
          ),
        ),
      ),
    );
  }
}
