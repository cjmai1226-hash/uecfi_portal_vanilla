import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/activity_log.dart';
import '../models/member.dart';
import '../models/post.dart';
import '../models/transfer_request.dart';

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Stream of currently authenticated member profile
  Stream<Member?> getCurrentMemberStream() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value(null);
    }

    final userEmail = user.email?.trim().toLowerCase();
    if (userEmail == null || userEmail.isEmpty) {
      return Stream.value(null);
    }

    return _firestore
        .collection('members')
        .where('email', isEqualTo: userEmail)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        return Member.fromFirestore(snapshot.docs.first);
      }
      return null;
    }).handleError((error) {
      debugPrint('Error getting current member profile: $error');
      return null;
    });
  }

  /// One-time fetch of current authenticated member profile
  Future<Member?> getCurrentMember() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final userEmail = user.email?.trim().toLowerCase();
    if (userEmail != null && userEmail.isNotEmpty) {
      try {
        final query = await _firestore
            .collection('members')
            .where('email', isEqualTo: userEmail)
            .limit(1)
            .get();
        if (query.docs.isNotEmpty) {
          return Member.fromFirestore(query.docs.first);
        }
      } catch (e) {
        debugPrint('Error fetching member by email: $e');
      }
    }

    try {
      final doc = await _firestore.collection('members').doc(user.uid).get();
      if (doc.exists) {
        return Member.fromFirestore(doc);
      }
    } catch (_) {}

    return null;
  }

  /// Stream of Members from Firestore 'members' collection
  Stream<List<Member>> getMembersStream({
    String? district,
    String? area,
    String? center,
  }) {
    Query query = _firestore.collection('members');

    if (district != null && district.isNotEmpty && district != 'All' && district != 'All Districts') {
      query = query.where('district', isEqualTo: district);
    }

    if (area != null && area.isNotEmpty && area != 'All' && area != 'All Areas') {
      query = query.where('area', isEqualTo: area);
    }

    if (center != null && center.isNotEmpty && center != 'All' && center != 'All Local Centers') {
      query = query.where('center', isEqualTo: center);
    }

    return query.snapshots().map((snapshot) {
      final members = snapshot.docs
          .map((doc) => Member.fromFirestore(doc))
          .where((m) => m.fullName.trim().isNotEmpty)
          .toList();
      // Sort alphabetically by full name
      members.sort((a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()));
      return members;
    }).handleError((error) {
      debugPrint('Firestore members stream error: $error');
      return <Member>[];
    });
  }

  /// One-time fetch of all Members from Firestore
  Future<List<Member>> getMembersOnce() async {
    try {
      final snapshot = await _firestore.collection('members').get();
      return snapshot.docs
          .map((doc) => Member.fromFirestore(doc))
          .where((m) => m.fullName.trim().isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('Error getting members: $e');
      return <Member>[];
    }
  }

  /// Helper to resolve current authenticated actor details
  Future<Map<String, String>> _getActorInfo() async {
    final user = _auth.currentUser;
    if (user == null) {
      return {
        'name': 'System / Admin',
        'uid': 'system-admin',
        'role': 'admin',
      };
    }

    try {
      final member = await getCurrentMember();
      final name = (member != null && member.fullName.trim().isNotEmpty)
          ? member.fullName.trim()
          : (user.displayName?.isNotEmpty == true
              ? user.displayName!
              : (user.email?.isNotEmpty == true
                  ? user.email!.split('@').first
                  : 'Administrator'));

      final uid = user.uid;
      final role = (member != null && member.role.isNotEmpty)
          ? member.role
          : 'admin';

      return {
        'name': name,
        'uid': uid,
        'role': role,
      };
    } catch (_) {
      return {
        'name': user.displayName ?? user.email?.split('@').first ?? 'Administrator',
        'uid': user.uid,
        'role': 'admin',
      };
    }
  }

  /// Add a new Member document to Firestore and automatically log the activity
  Future<String> addMember(Member member, {String? customActorName}) async {
    try {
      final docRef = await _firestore.collection('members').add(member.toMap());

      // Record activity log with exact requested schema
      try {
        final actor = await _getActorInfo();
        await logActivity(
          ActivityLog(
            id: '',
            action: 'ADD_MEMBER',
            area: member.area,
            center: member.center,
            description: 'Added new member: ${member.fullName} (${member.memberId})',
            district: member.district.isNotEmpty ? member.district : 'District 3',
            performedByName: customActorName ?? actor['name']!,
            performedByUid: actor['uid']!,
            role: actor['role']!,
            timestamp: DateTime.now(),
          ),
        );
      } catch (logErr) {
        debugPrint('Activity log error on add: $logErr');
      }

      return docRef.id;
    } catch (e) {
      debugPrint('Error adding member: $e');
      rethrow;
    }
  }

  /// Update an existing Member document in Firestore and automatically log the activity
  Future<void> updateMember(
    Member member, {
    String? customDetails,
    String? customActorName,
  }) async {
    try {
      if (member.id.isNotEmpty) {
        await _firestore.collection('members').doc(member.id).update(member.toMap());
      } else {
        final snapshot = await _firestore
            .collection('members')
            .where('memberId', isEqualTo: member.memberId)
            .limit(1)
            .get();
        if (snapshot.docs.isNotEmpty) {
          await snapshot.docs.first.reference.update(member.toMap());
        }
      }

      // Record activity log with exact requested schema
      try {
        final actor = await _getActorInfo();
        await logActivity(
          ActivityLog(
            id: '',
            action: 'UPDATE_MEMBER',
            area: member.area,
            center: member.center,
            description: customDetails ?? 'Updated profile for ${member.fullName} (${member.memberId})',
            district: member.district.isNotEmpty ? member.district : 'District 3',
            performedByName: customActorName ?? actor['name']!,
            performedByUid: actor['uid']!,
            role: actor['role']!,
            timestamp: DateTime.now(),
          ),
        );
      } catch (logErr) {
        debugPrint('Activity log error on update: $logErr');
      }
    } catch (e) {
      debugPrint('Error updating member: $e');
      rethrow;
    }
  }

  /// Delete a Member document from Firestore and automatically log the activity
  Future<void> deleteMember(Member member, {String? customActorName}) async {
    try {
      if (member.id.isNotEmpty) {
        await _firestore.collection('members').doc(member.id).delete();
      } else if (member.memberId.isNotEmpty) {
        final snapshot = await _firestore
            .collection('members')
            .where('memberId', isEqualTo: member.memberId)
            .limit(1)
            .get();
        if (snapshot.docs.isNotEmpty) {
          await snapshot.docs.first.reference.delete();
        }
      }

      // Record activity log with exact requested schema
      try {
        final actor = await _getActorInfo();
        await logActivity(
          ActivityLog(
            id: '',
            action: 'DELETE_MEMBER',
            area: member.area,
            center: member.center,
            description: 'Deleted member record: ${member.fullName} (${member.memberId})',
            district: member.district.isNotEmpty ? member.district : 'District 3',
            performedByName: customActorName ?? actor['name']!,
            performedByUid: actor['uid']!,
            role: actor['role']!,
            timestamp: DateTime.now(),
          ),
        );
      } catch (logErr) {
        debugPrint('Activity log error on delete: $logErr');
      }
    } catch (e) {
      debugPrint('Error deleting member: $e');
      rethrow;
    }
  }

  /// Stream of District Posts ordered by pinned status and creation date
  Stream<List<Post>> getPostsStream({String? category}) {
    Query query = _firestore.collection('posts');

    if (category != null && category.isNotEmpty && category != 'All') {
      query = query.where('category', isEqualTo: category);
    }

    return query.snapshots().map((snapshot) {
      final posts = snapshot.docs.map((doc) => Post.fromFirestore(doc)).toList();

      // Sort: pinned posts first, then descending by createdAt
      posts.sort((a, b) {
        if (a.isPinned != b.isPinned) {
          return a.isPinned ? -1 : 1;
        }
        try {
          final dateA = DateTime.tryParse(a.createdAt) ?? DateTime(2000);
          final dateB = DateTime.tryParse(b.createdAt) ?? DateTime(2000);
          return dateB.compareTo(dateA);
        } catch (_) {
          return 0;
        }
      });

      return posts;
    }).handleError((error) {
      debugPrint('Firestore posts stream error: $error');
      return <Post>[];
    });
  }

  /// Create and publish a new post
  Future<String> createPost(Post post) async {
    try {
      final docRef = await _firestore.collection('posts').add(post.toMap());
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating post: $e');
      rethrow;
    }
  }

  /// Update an existing post
  Future<void> updatePost(Post post) async {
    try {
      if (post.id.isNotEmpty) {
        await _firestore.collection('posts').doc(post.id).update({
          'title': post.title,
          'content': post.content,
          'category': post.category,
          'isPinned': post.isPinned,
          'authorName': post.authorName,
          'authorRole': post.authorRole,
          'authorCenter': post.authorCenter,
        });
      }
    } catch (e) {
      debugPrint('Error updating post: $e');
      rethrow;
    }
  }

  /// Delete a post
  Future<void> deletePost(String postId) async {
    try {
      if (postId.isNotEmpty) {
        await _firestore.collection('posts').doc(postId).delete();
      }
    } catch (e) {
      debugPrint('Error deleting post: $e');
      rethrow;
    }
  }

  /// Toggle pin status for a post
  Future<void> togglePinPost(String postId, bool isPinned) async {
    try {
      if (postId.isNotEmpty) {
        await _firestore.collection('posts').doc(postId).update({
          'isPinned': isPinned,
        });
      }
    } catch (e) {
      debugPrint('Error toggling pin status: $e');
      rethrow;
    }
  }

  /// Record an ActivityLog entry to activity_logs collection
  Future<void> logActivity(ActivityLog log) async {
    try {
      await _firestore.collection('activity_logs').add(log.toMap());
    } catch (e) {
      debugPrint('Error writing activity log: $e');
    }
  }

  /// Stream of Activity Logs ordered chronologically descending
  Stream<List<ActivityLog>> getActivityLogsStream({
    int limit = 150,
  }) {
    final query = _firestore
        .collection('activity_logs')
        .orderBy('timestamp', descending: true)
        .limit(limit);

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => ActivityLog.fromFirestore(doc)).toList();
    }).handleError((error) {
      debugPrint('Error streaming activity logs: $error');
      return <ActivityLog>[];
    });
  }

  // ==========================================
  // MEMBER LOCAL CENTER TRANSFERS
  // ==========================================

  /// Submit a new member local center transfer request
  Future<String> createTransferRequest(TransferRequest request) async {
    try {
      final docRef = await _firestore.collection('transfer_requests').add(request.toMap());

      // Log activity
      try {
        final actor = await _getActorInfo();
        await logActivity(
          ActivityLog(
            id: '',
            action: 'REQUEST_TRANSFER',
            area: request.fromArea,
            center: request.fromCenter,
            description: 'Submitted transfer request for ${request.memberName} to ${request.toCenter}',
            district: request.fromDistrict,
            performedByName: actor['name']!,
            performedByUid: actor['uid']!,
            role: actor['role']!,
            timestamp: DateTime.now(),
          ),
        );
      } catch (logErr) {
        debugPrint('Activity log error on transfer request: $logErr');
      }

      return docRef.id;
    } catch (e) {
      debugPrint('Error creating transfer request: $e');
      rethrow;
    }
  }

  /// Stream of transfer requests with optional status filter
  Stream<List<TransferRequest>> getTransferRequestsStream({
    String? status,
    String? memberDocId,
  }) {
    Query query = _firestore.collection('transfer_requests');

    if (status != null && status.isNotEmpty && status.toLowerCase() != 'all') {
      query = query.where('status', isEqualTo: status.toLowerCase());
    }

    if (memberDocId != null && memberDocId.isNotEmpty) {
      query = query.where('memberDocId', isEqualTo: memberDocId);
    }

    return query.snapshots().map((snapshot) {
      final requests = snapshot.docs
          .map((doc) => TransferRequest.fromFirestore(doc))
          .toList();
      requests.sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
      return requests;
    }).handleError((error) {
      debugPrint('Error streaming transfer requests: $error');
      return <TransferRequest>[];
    });
  }

  /// Check if a member has an active pending transfer request
  Future<TransferRequest?> getPendingTransferForMember(String memberDocId) async {
    try {
      final snapshot = await _firestore
          .collection('transfer_requests')
          .where('memberDocId', isEqualTo: memberDocId)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return TransferRequest.fromFirestore(snapshot.docs.first);
      }
      return null;
    } catch (e) {
      debugPrint('Error checking pending transfer: $e');
      return null;
    }
  }

  /// Stream to listen for pending transfer for a specific member
  Stream<TransferRequest?> getPendingTransferStream(String memberDocId) {
    return _firestore
        .collection('transfer_requests')
        .where('memberDocId', isEqualTo: memberDocId)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        return TransferRequest.fromFirestore(snapshot.docs.first);
      }
      return null;
    }).handleError((error) {
      debugPrint('Error streaming pending transfer: $error');
      return null;
    });
  }

  /// Stream of all transfer history for a specific member
  Stream<List<TransferRequest>> getMemberTransferHistoryStream(String memberDocId) {
    return _firestore
        .collection('transfer_requests')
        .where('memberDocId', isEqualTo: memberDocId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => TransferRequest.fromFirestore(doc))
          .toList();
      list.sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
      return list;
    }).handleError((error) {
      debugPrint('Error streaming member transfer history: $error');
      return <TransferRequest>[];
    });
  }

  /// Stream of pending transfer requests count (useful for badges)
  Stream<int> getPendingTransfersCountStream() {
    return _firestore
        .collection('transfer_requests')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs.length)
        .handleError((error) {
      debugPrint('Error streaming pending transfers count: $error');
      return 0;
    });
  }

  /// Approve a transfer request: updates member affiliation and marks request approved
  Future<void> approveTransferRequest({
    required TransferRequest request,
    String? notes,
    String? customActorName,
  }) async {
    try {
      final actor = await _getActorInfo();
      final reviewerName = customActorName ?? actor['name']!;
      final reviewerUid = actor['uid']!;
      final now = DateTime.now();

      // 1. Update transfer request status
      await _firestore.collection('transfer_requests').doc(request.id).update({
        'status': 'approved',
        'reviewedByUid': reviewerUid,
        'reviewedByName': reviewerName,
        'reviewedAt': Timestamp.fromDate(now),
        if (notes != null && notes.trim().isNotEmpty) 'reviewNotes': notes.trim(),
      });

      // 2. Update member document in Firestore
      final memberUpdates = {
        'center': request.toCenter,
        'area': request.toArea,
        'district': request.toDistrict,
        'updatedAt': now.toIso8601String(),
      };

      if (request.memberDocId.isNotEmpty) {
        await _firestore.collection('members').doc(request.memberDocId).update(memberUpdates);
      } else if (request.memberId.isNotEmpty) {
        final memberSnap = await _firestore
            .collection('members')
            .where('memberId', isEqualTo: request.memberId)
            .limit(1)
            .get();
        if (memberSnap.docs.isNotEmpty) {
          await memberSnap.docs.first.reference.update(memberUpdates);
        }
      }

      // 3. Log activity audit trail
      try {
        await logActivity(
          ActivityLog(
            id: '',
            action: 'TRANSFER_MEMBER',
            area: request.toArea,
            center: request.toCenter,
            description: 'Approved transfer of ${request.memberName} from ${request.fromCenter} to ${request.toCenter}',
            district: request.toDistrict,
            performedByName: reviewerName,
            performedByUid: reviewerUid,
            role: actor['role']!,
            timestamp: now,
          ),
        );
      } catch (logErr) {
        debugPrint('Activity log error on approve transfer: $logErr');
      }
    } catch (e) {
      debugPrint('Error approving transfer request: $e');
      rethrow;
    }
  }

  /// Reject a transfer request with reason
  Future<void> rejectTransferRequest({
    required TransferRequest request,
    required String notes,
    String? customActorName,
  }) async {
    try {
      final actor = await _getActorInfo();
      final reviewerName = customActorName ?? actor['name']!;
      final reviewerUid = actor['uid']!;
      final now = DateTime.now();

      // 1. Update transfer request status
      await _firestore.collection('transfer_requests').doc(request.id).update({
        'status': 'rejected',
        'reviewedByUid': reviewerUid,
        'reviewedByName': reviewerName,
        'reviewedAt': Timestamp.fromDate(now),
        'reviewNotes': notes.trim(),
      });

      // 2. Log activity audit trail
      try {
        await logActivity(
          ActivityLog(
            id: '',
            action: 'REJECT_TRANSFER',
            area: request.fromArea,
            center: request.fromCenter,
            description: 'Declined transfer of ${request.memberName} to ${request.toCenter}. Reason: ${notes.trim()}',
            district: request.fromDistrict,
            performedByName: reviewerName,
            performedByUid: reviewerUid,
            role: actor['role']!,
            timestamp: now,
          ),
        );
      } catch (logErr) {
        debugPrint('Activity log error on reject transfer: $logErr');
      }
    } catch (e) {
      debugPrint('Error rejecting transfer request: $e');
      rethrow;
    }
  }
}

