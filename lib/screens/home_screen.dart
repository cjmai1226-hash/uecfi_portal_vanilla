import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/member.dart';
import '../models/post.dart';
import '../services/firestore_service.dart';
import '../widgets/formatted_post_text.dart';
import 'create_post_screen.dart';

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

  void _showPostDetails(BuildContext context, Post post) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final textPrimary = isDark ? const Color(0xFFF5F5FA) : const Color(0xFF0E0E14);
    final textSecondary = isDark ? const Color(0xFF9E9EAF) : const Color(0xFF6E6E82);
    final cardBg = isDark ? const Color(0xFF1E1E2A) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2E2E3E) : const Color(0xFFE5E5ED);
    final initial = post.authorName.isNotEmpty ? post.authorName[0].toUpperCase() : 'D';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StreamBuilder<Member?>(
        stream: FirestoreService().getCurrentMemberStream(),
        builder: (context, snapshot) {
          final currentMember = snapshot.data;
          final currentUser = FirebaseAuth.instance.currentUser;
          final userRole = currentMember?.role.toLowerCase() ?? 'admin';
          final isAdmin = userRole == 'admin';
          final isAuthor = (currentMember != null &&
                  (post.authorId == currentMember.id || post.authorId == currentMember.memberId)) ||
              (currentUser != null && post.authorId == currentUser.uid);
          final canManage = isAdmin || isAuthor;

          return DraggableScrollableSheet(
            initialChildSize: 0.75,
            minChildSize: 0.45,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) => SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Drag Handle
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white24 : Colors.black12,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Category Badge & Action Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: isDark ? 0.25 : 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            post.category.toUpperCase(),
                            style: TextStyle(
                              color: primaryColor,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        if (canManage)
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 20),
                                color: textSecondary,
                                tooltip: 'Edit Post',
                                onPressed: () {
                                  Navigator.of(ctx).pop();
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => CreatePostScreen(postToEdit: post),
                                    ),
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, size: 20),
                                color: const Color(0xFFFF2A55),
                                tooltip: 'Delete Post',
                                onPressed: () {
                                  Navigator.of(ctx).pop();
                                  _confirmDeletePost(context, post);
                                },
                              ),
                            ],
                          )
                        else
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 22),
                            color: textSecondary,
                            onPressed: () => Navigator.of(ctx).pop(),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Title
                    Text(
                      post.title,
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Author Metadata Card
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: primaryColor.withValues(alpha: 0.12),
                          child: Text(
                            initial,
                            style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                post.authorName,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: textPrimary,
                                ),
                              ),
                              Text(
                                '${post.authorRole} • ${post.authorCenter} • ${post.timeAgo}',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),
                    Divider(color: borderColor),
                    const SizedBox(height: 10),

                    // Full Content
                    Expanded(
                      child: SingleChildScrollView(
                        controller: scrollController,
                        physics: const BouncingScrollPhysics(),
                        child: FormattedPostText(
                          text: post.content,
                          baseStyle: TextStyle(
                            fontSize: 14.5,
                            height: 1.6,
                            color: textPrimary,
                          ),
                          accentColor: primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
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
                StreamBuilder<Member?>(
                  stream: firestoreService.getCurrentMemberStream(),
                  builder: (context, memberSnapshot) {
                    final currentMember = memberSnapshot.data;
                    final canCreate = currentMember != null && currentMember.canCreateDistrictPosts;

                    if (!canCreate) {
                      return const SizedBox.shrink();
                    }

                    return Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      child: InkWell(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const CreatePostScreen()),
                          );
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add_circle_outline_rounded, size: 16, color: primaryColor),
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
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Live Posts Feed
            StreamBuilder<List<Post>>(
              stream: firestoreService.getPostsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 36),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final posts = snapshot.data ?? [];

                if (posts.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
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
                          style: TextStyle(fontSize: 12.5, color: textSecondary),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: posts.map((post) {
                    final isPinned = post.isPinned;
                    final initial = post.authorName.isNotEmpty ? post.authorName[0].toUpperCase() : 'D';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isPinned ? primaryColor.withValues(alpha: 0.6) : borderColor,
                          width: isPinned ? 1.5 : 1.1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.02),
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
                          onTap: () => _showPostDetails(context, post),
                          splashColor: primaryColor.withValues(alpha: 0.12),
                          hoverColor: primaryColor.withValues(alpha: 0.04),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 17,
                                      backgroundColor: primaryColor.withValues(alpha: 0.12),
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
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            post.authorName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: textPrimary,
                                            ),
                                          ),
                                          Text(
                                            '${post.authorRole} • ${post.timeAgo}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: textSecondary,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isPinned) ...[
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.amber.withValues(alpha: isDark ? 0.25 : 0.12),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(
                                            color: Colors.amber.withValues(alpha: 0.5),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.push_pin_rounded,
                                              size: 10,
                                              color: Colors.amber.shade800,
                                            ),
                                            const SizedBox(width: 3),
                                            Text(
                                              'Pinned',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.amber.shade800,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                  decoration: BoxDecoration(
                                    color: primaryColor.withValues(alpha: 0.10),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    post.category.toUpperCase(),
                                    style: TextStyle(
                                      color: primaryColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.7,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  post.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                FormattedPostText(
                                  text: post.content.length > 180
                                      ? '${post.content.substring(0, 177)}...'
                                      : post.content,
                                  baseStyle: TextStyle(
                                    fontSize: 13,
                                    height: 1.45,
                                    color: textSecondary,
                                  ),
                                  accentColor: primaryColor,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
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
