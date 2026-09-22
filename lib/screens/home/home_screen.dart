import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/member.dart';
import '../../models/post.dart';
import '../../services/firestore_service.dart';
import '../../widgets/formatted_post_text.dart';
import '../posts/create_post_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _confirmDeletePost(BuildContext context, Post post) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete District Post?'),
        content: Text(
          'Are you sure you want to delete "${post.title}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF2A55),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await FirestoreService().deletePost(post.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Post deleted successfully'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete post: $e'),
                      backgroundColor: const Color(0xFFFF2A55),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showPostOptionsBottomSheet(BuildContext context, Post post) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? const Color(0xFFF5F5FA) : const Color(0xFF0E0E14);
    final cardBg = isDark ? const Color(0xFF1C1C28) : Colors.white;

    showModalBottomSheet(
      context: context,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF333345)
                        : const Color(0xFFE0E0E8),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.edit_outlined, color: textPrimary),
                  title: Text(
                    'Edit Post',
                    style: TextStyle(
                      color: textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CreatePostScreen(postToEdit: post),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline_rounded,
                    color: Color(0xFFFF2A55),
                  ),
                  title: const Text(
                    'Delete Post',
                    style: TextStyle(
                      color: Color(0xFFFF2A55),
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _confirmDeletePost(context, post);
                  },
                ),
              ],
            ),
          ),
        );
      },
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
    final firestoreService = FirestoreService();

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: borderColor, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DISTRICT 3 PORTAL',
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.6,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'District Communications',
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Welcome to the Union Espiritista Cristiana de Filipinas, Inc. portal dashboard.',
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Section Header & Live Posts Feed
            StreamBuilder<Member?>(
              stream: firestoreService.getCurrentMemberStream(),
              builder: (context, memberSnapshot) {
                final currentMember = memberSnapshot.data;
                final currentUser = FirebaseAuth.instance.currentUser;
                final userRole = currentMember?.role.toLowerCase() ?? 'admin';
                final isAdmin = userRole == 'admin';
                final canCreate = currentMember != null && currentMember.canCreateDistrictPosts;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section Header: Announcements & District Posts
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'DISTRICT POSTS & ADVISORIES',
                          style: TextStyle(
                            color: primaryColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.4,
                          ),
                        ),
                        if (canCreate)
                          Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            child: InkWell(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const CreatePostScreen(),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.add_circle_outline_rounded,
                                        size: 16, color: primaryColor),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Create Post',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                        color: primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Live Posts Feed
                    StreamBuilder<List<Post>>(
                      stream: firestoreService.getPostsStream(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                                ConnectionState.waiting &&
                            !snapshot.hasData) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 36),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }

                        final posts = snapshot.data ?? [];

                        if (posts.isEmpty) {
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 32),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: borderColor),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.campaign_outlined,
                                  size: 48,
                                  color: textSecondary.withValues(alpha: 0.4),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'No District Announcements Yet',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Official district circulars, letters, and event updates will appear here.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 12.5, color: textSecondary),
                                ),
                              ],
                            ),
                          );
                        }

                        return Column(
                          children: posts.map((post) {
                            final initial = post.authorName.isNotEmpty
                                ? post.authorName[0].toUpperCase()
                                : 'D';
                            final isAuthor = (currentMember != null &&
                                    (post.authorId == currentMember.id ||
                                        post.authorId ==
                                            currentMember.memberId)) ||
                                (currentUser != null &&
                                    post.authorId == currentUser.uid);
                            final canManage = isAdmin || isAuthor;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: cardBg,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: borderColor,
                                  width: 1.1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(
                                        alpha: isDark ? 0.20 : 0.02),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(18),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Author & Action Buttons
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        CircleAvatar(
                                          radius: 17,
                                          backgroundColor: primaryColor
                                              .withValues(alpha: 0.12),
                                          child: Text(
                                            initial,
                                            style: TextStyle(
                                              color: primaryColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                post.authorName,
                                                maxLines: 1,
                                                overflow:
                                                    TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w700,
                                                  color: textPrimary,
                                                ),
                                              ),
                                              Text(
                                                '${post.authorRole.isNotEmpty ? '${post.authorRole} • ' : ''}${post.timeAgo}',
                                                maxLines: 1,
                                                overflow:
                                                    TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: textSecondary,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (canManage)
                                          IconButton(
                                            icon: const Icon(
                                              Icons.more_horiz_rounded,
                                              size: 20,
                                            ),
                                            color: textSecondary,
                                            tooltip: 'Post options',
                                            visualDensity:
                                                VisualDensity.compact,
                                            padding: EdgeInsets.zero,
                                            constraints:
                                                const BoxConstraints(
                                                    minWidth: 32,
                                                    minHeight: 32),
                                            onPressed: () =>
                                                _showPostOptionsBottomSheet(
                                                    context, post),
                                          ),
                                      ],
                                    ),

                                    const SizedBox(height: 12),
                                    Divider(color: borderColor, height: 1),
                                    const SizedBox(height: 12),

                                    // Full Title
                                    Text(
                                      post.title,
                                      style: TextStyle(
                                        fontSize: 16.5,
                                        fontWeight: FontWeight.bold,
                                        color: textPrimary,
                                        height: 1.3,
                                      ),
                                    ),

                                    const SizedBox(height: 8),

                                    // Entire Post Content (Full, un-truncated)
                                    FormattedPostText(
                                      text: post.content,
                                      baseStyle: TextStyle(
                                        fontSize: 13.5,
                                        height: 1.55,
                                        color: isDark
                                            ? const Color(0xFFE2E2EC)
                                            : const Color(0xFF33333F),
                                      ),
                                      accentColor: primaryColor,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
