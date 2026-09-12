import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class Post {
  final String id;
  final String authorId;
  final String authorName;
  final String authorRole;
  final String authorProfileUrl;
  final String authorCenter;
  final String title;
  final String content;
  final String category; // 'Announcement', 'Pastoral Letter', 'Update', 'Event', 'General'
  final String createdAt;
  final bool isPinned;

  const Post({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorRole = 'Pastor',
    this.authorProfileUrl = '',
    this.authorCenter = 'Central District 3',
    required this.title,
    required this.content,
    this.category = 'Announcement',
    required this.createdAt,
    this.isPinned = false,
  });

  String get formattedDate {
    try {
      final dt = DateTime.parse(createdAt);
      return DateFormat('MMM d, yyyy • h:mm a').format(dt);
    } catch (_) {
      return createdAt;
    }
  }

  String get shortDate {
    try {
      final dt = DateTime.parse(createdAt);
      return DateFormat('MMM d, yyyy').format(dt);
    } catch (_) {
      return createdAt;
    }
  }

  String get timeAgo {
    try {
      final dt = DateTime.parse(createdAt);
      final diff = DateTime.now().difference(dt);
      if (diff.inDays > 30) {
        return DateFormat('MMM d, yyyy').format(dt);
      } else if (diff.inDays > 0) {
        return '${diff.inDays}d ago';
      } else if (diff.inHours > 0) {
        return '${diff.inHours}h ago';
      } else if (diff.inMinutes > 0) {
        return '${diff.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (_) {
      return createdAt;
    }
  }

  factory Post.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    String formatTimestamp(dynamic val) {
      if (val is Timestamp) {
        return val.toDate().toIso8601String();
      } else if (val is String) {
        return val;
      }
      return DateTime.now().toIso8601String();
    }

    return Post(
      id: doc.id,
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? 'District Official',
      authorRole: data['authorRole'] ?? 'District Official',
      authorProfileUrl: data['authorProfileUrl'] ?? '',
      authorCenter: data['authorCenter'] ?? 'District 3',
      title: data['title'] ?? 'Untitled Post',
      content: data['content'] ?? '',
      category: data['category'] ?? 'Announcement',
      createdAt: formatTimestamp(data['createdAt']),
      isPinned: data['isPinned'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'authorId': authorId,
      'authorName': authorName,
      'authorRole': authorRole,
      'authorProfileUrl': authorProfileUrl,
      'authorCenter': authorCenter,
      'title': title,
      'content': content,
      'category': category,
      'createdAt': FieldValue.serverTimestamp(),
      'isPinned': isPinned,
    };
  }

  Post copyWith({
    String? id,
    String? authorId,
    String? authorName,
    String? authorRole,
    String? authorProfileUrl,
    String? authorCenter,
    String? title,
    String? content,
    String? category,
    String? createdAt,
    bool? isPinned,
  }) {
    return Post(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorRole: authorRole ?? this.authorRole,
      authorProfileUrl: authorProfileUrl ?? this.authorProfileUrl,
      authorCenter: authorCenter ?? this.authorCenter,
      title: title ?? this.title,
      content: content ?? this.content,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      isPinned: isPinned ?? this.isPinned,
    );
  }
}
