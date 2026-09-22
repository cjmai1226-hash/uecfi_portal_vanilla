import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ActivityLog {
  final String id;
  final String action;
  final String area;
  final String center;
  final String description;
  final String district;
  final String performedByName;
  final String performedByUid;
  final String role;
  final DateTime timestamp;

  const ActivityLog({
    required this.id,
    required this.action,
    required this.area,
    required this.center,
    required this.description,
    required this.district,
    required this.performedByName,
    required this.performedByUid,
    required this.role,
    required this.timestamp,
  });

  String get actionDisplayName {
    final act = action.toUpperCase();
    if (act.contains('ADD') || act.contains('CREATE')) {
      return 'Member Added';
    } else if (act.contains('UPDATE') || act.contains('EDIT')) {
      return 'Member Updated';
    } else if (act.contains('DELETE') || act.contains('REMOVE')) {
      return 'Member Deleted';
    }
    return action;
  }

  Color get actionColor {
    final act = action.toUpperCase();
    if (act.contains('ADD') || act.contains('CREATE')) {
      return const Color(0xFF00C853); // Emerald Green
    } else if (act.contains('UPDATE') || act.contains('EDIT')) {
      return const Color(0xFFA100FF); // Electric Violet
    } else if (act.contains('DELETE') || act.contains('REMOVE')) {
      return const Color(0xFFFF2A55); // Crimson Red
    }
    return const Color(0xFF00E5FF);
  }

  IconData get actionIcon {
    final act = action.toUpperCase();
    if (act.contains('ADD') || act.contains('CREATE')) {
      return Icons.person_add_rounded;
    } else if (act.contains('UPDATE') || act.contains('EDIT')) {
      return Icons.edit_note_rounded;
    } else if (act.contains('DELETE') || act.contains('REMOVE')) {
      return Icons.person_remove_rounded;
    }
    return Icons.history_rounded;
  }

  String get timeAgo {
    final difference = DateTime.now().difference(timestamp);
    if (difference.inDays > 7) {
      return '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')}';
    } else if (difference.inDays >= 1) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours >= 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes >= 1) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  factory ActivityLog.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    DateTime parsedDate;
    final rawTimestamp = data['timestamp'];
    if (rawTimestamp is Timestamp) {
      parsedDate = rawTimestamp.toDate();
    } else if (rawTimestamp is String) {
      parsedDate = DateTime.tryParse(rawTimestamp) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    return ActivityLog(
      id: doc.id,
      action: data['action']?.toString() ?? '',
      area: data['area']?.toString() ?? '',
      center: data['center']?.toString() ?? '',
      description: data['description']?.toString() ?? data['details']?.toString() ?? '',
      district: data['district']?.toString() ?? '',
      performedByName: data['performedByName']?.toString() ??
          data['performedBy']?.toString() ??
          'System / Admin',
      performedByUid: data['performedByUid']?.toString() ?? '',
      role: data['role']?.toString() ??
          data['performedByRole']?.toString() ??
          'admin',
      timestamp: parsedDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'action': action,
      'area': area,
      'center': center,
      'description': description,
      'district': district,
      'performedByName': performedByName,
      'performedByUid': performedByUid,
      'role': role,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
