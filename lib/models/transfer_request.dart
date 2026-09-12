import 'package:cloud_firestore/cloud_firestore.dart';

class TransferRequest {
  final String id;
  final String memberDocId;
  final String memberId;
  final String memberName;
  final String fromCenter;
  final String fromArea;
  final String fromDistrict;
  final String toCenter;
  final String toArea;
  final String toDistrict;
  final String reason;
  final String status; // 'pending', 'approved', 'rejected'
  final String requestedByUid;
  final String requestedByName;
  final DateTime requestedAt;
  final String? reviewedByUid;
  final String? reviewedByName;
  final DateTime? reviewedAt;
  final String? reviewNotes;

  const TransferRequest({
    required this.id,
    required this.memberDocId,
    required this.memberId,
    required this.memberName,
    required this.fromCenter,
    required this.fromArea,
    required this.fromDistrict,
    required this.toCenter,
    required this.toArea,
    required this.toDistrict,
    required this.reason,
    this.status = 'pending',
    required this.requestedByUid,
    required this.requestedByName,
    required this.requestedAt,
    this.reviewedByUid,
    this.reviewedByName,
    this.reviewedAt,
    this.reviewNotes,
  });

  bool get isPending => status.toLowerCase() == 'pending';
  bool get isApproved => status.toLowerCase() == 'approved';
  bool get isRejected => status.toLowerCase() == 'rejected';

  TransferRequest copyWith({
    String? id,
    String? memberDocId,
    String? memberId,
    String? memberName,
    String? fromCenter,
    String? fromArea,
    String? fromDistrict,
    String? toCenter,
    String? toArea,
    String? toDistrict,
    String? reason,
    String? status,
    String? requestedByUid,
    String? requestedByName,
    DateTime? requestedAt,
    String? reviewedByUid,
    String? reviewedByName,
    DateTime? reviewedAt,
    String? reviewNotes,
  }) {
    return TransferRequest(
      id: id ?? this.id,
      memberDocId: memberDocId ?? this.memberDocId,
      memberId: memberId ?? this.memberId,
      memberName: memberName ?? this.memberName,
      fromCenter: fromCenter ?? this.fromCenter,
      fromArea: fromArea ?? this.fromArea,
      fromDistrict: fromDistrict ?? this.fromDistrict,
      toCenter: toCenter ?? this.toCenter,
      toArea: toArea ?? this.toArea,
      toDistrict: toDistrict ?? this.toDistrict,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      requestedByUid: requestedByUid ?? this.requestedByUid,
      requestedByName: requestedByName ?? this.requestedByName,
      requestedAt: requestedAt ?? this.requestedAt,
      reviewedByUid: reviewedByUid ?? this.reviewedByUid,
      reviewedByName: reviewedByName ?? this.reviewedByName,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewNotes: reviewNotes ?? this.reviewNotes,
    );
  }

  factory TransferRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return TransferRequest.fromMap(data, id: doc.id);
  }

  factory TransferRequest.fromMap(Map<String, dynamic> map, {String id = ''}) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) {
        final parsed = DateTime.tryParse(val);
        if (parsed != null) return parsed;
      }
      return DateTime.now();
    }

    DateTime? parseNullableDate(dynamic val) {
      if (val == null) return null;
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    return TransferRequest(
      id: id.isNotEmpty ? id : (map['id']?.toString() ?? ''),
      memberDocId: map['memberDocId']?.toString() ?? '',
      memberId: map['memberId']?.toString() ?? '',
      memberName: map['memberName']?.toString() ?? '',
      fromCenter: map['fromCenter']?.toString() ?? '',
      fromArea: map['fromArea']?.toString() ?? '',
      fromDistrict: map['fromDistrict']?.toString() ?? 'District 3',
      toCenter: map['toCenter']?.toString() ?? '',
      toArea: map['toArea']?.toString() ?? '',
      toDistrict: map['toDistrict']?.toString() ?? 'District 3',
      reason: map['reason']?.toString() ?? '',
      status: map['status']?.toString() ?? 'pending',
      requestedByUid: map['requestedByUid']?.toString() ?? '',
      requestedByName: map['requestedByName']?.toString() ?? '',
      requestedAt: parseDate(map['requestedAt']),
      reviewedByUid: map['reviewedByUid']?.toString(),
      reviewedByName: map['reviewedByName']?.toString(),
      reviewedAt: parseNullableDate(map['reviewedAt']),
      reviewNotes: map['reviewNotes']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'memberDocId': memberDocId,
      'memberId': memberId,
      'memberName': memberName,
      'fromCenter': fromCenter,
      'fromArea': fromArea,
      'fromDistrict': fromDistrict,
      'toCenter': toCenter,
      'toArea': toArea,
      'toDistrict': toDistrict,
      'reason': reason,
      'status': status,
      'requestedByUid': requestedByUid,
      'requestedByName': requestedByName,
      'requestedAt': Timestamp.fromDate(requestedAt),
      if (reviewedByUid != null) 'reviewedByUid': reviewedByUid,
      if (reviewedByName != null) 'reviewedByName': reviewedByName,
      if (reviewedAt != null) 'reviewedAt': Timestamp.fromDate(reviewedAt!),
      if (reviewNotes != null) 'reviewNotes': reviewNotes,
    };
  }
}
