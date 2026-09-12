import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/date_formatter.dart';

enum MemberStatus { active, inactive, pending }

class MemberPosition {
  final String level;
  final String position;

  const MemberPosition({
    this.level = '',
    required this.position,
  });

  /// Single unified string e.g. "Local President" or "District Overseer"
  String get title {
    if (level.isNotEmpty &&
        !position.toLowerCase().startsWith(level.toLowerCase())) {
      return '$level $position'.trim();
    }
    return position.trim();
  }

  factory MemberPosition.fromDynamic(dynamic val) {
    if (val is Map<String, dynamic>) {
      return MemberPosition.fromMap(val);
    } else if (val is Map) {
      return MemberPosition.fromMap(Map<String, dynamic>.from(val));
    } else if (val is String) {
      return MemberPosition(level: '', position: val);
    }
    return const MemberPosition(level: '', position: 'Member');
  }

  factory MemberPosition.fromMap(Map<String, dynamic> map) {
    return MemberPosition(
      level: map['level']?.toString() ?? '',
      position: map['position']?.toString() ?? map['title']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'level': level,
      'position': position,
    };
  }
}

class Member {
  final String id;
  final String memberId;
  final String uid;
  final String role;
  final String status;
  final String firstName;
  final String middleName;
  final String lastName;
  final String dob;
  final String gender;
  final String civilStatus;
  final String category;
  final String email;
  final String contactNo;
  final String region;
  final String province;
  final String municipality;
  final String barangay;
  final String street;
  final String district;
  final String area;
  final String center;
  final List<MemberPosition> positions;
  final String membershipStatus;
  final String memberType;
  final String dateJoined;
  final String profileUrl;
  final String signatureUrl;
  final bool signatureDeclined;
  final String createdAt;
  final String updatedAt;

  const Member({
    required this.id,
    required this.memberId,
    this.uid = '',
    this.role = 'member',
    this.status = 'registered',
    required this.firstName,
    this.middleName = '',
    required this.lastName,
    this.dob = '',
    this.gender = 'Male',
    this.civilStatus = 'Single',
    this.category = 'Adult',
    required this.email,
    required this.contactNo,
    this.region = 'CALABARZON',
    this.province = 'Rizal',
    this.municipality = 'Antipolo',
    this.barangay = '',
    this.street = '',
    this.district = 'District 3',
    this.area = 'Area 1',
    required this.center,
    this.positions = const [],
    this.membershipStatus = 'Active',
    this.memberType = 'Regular',
    this.dateJoined = '',
    this.profileUrl = '',
    this.signatureUrl = '',
    this.signatureDeclined = false,
    this.createdAt = '',
    this.updatedAt = '',
  });

  Member copyWith({
    String? id,
    String? memberId,
    String? uid,
    String? role,
    String? status,
    String? firstName,
    String? middleName,
    String? lastName,
    String? dob,
    String? gender,
    String? civilStatus,
    String? category,
    String? email,
    String? contactNo,
    String? region,
    String? province,
    String? municipality,
    String? barangay,
    String? street,
    String? district,
    String? area,
    String? center,
    List<MemberPosition>? positions,
    String? membershipStatus,
    String? memberType,
    String? dateJoined,
    String? profileUrl,
    String? signatureUrl,
    bool? signatureDeclined,
    String? createdAt,
    String? updatedAt,
  }) {
    return Member(
      id: id ?? this.id,
      memberId: memberId ?? this.memberId,
      uid: uid ?? this.uid,
      role: role ?? this.role,
      status: status ?? this.status,
      firstName: firstName ?? this.firstName,
      middleName: middleName ?? this.middleName,
      lastName: lastName ?? this.lastName,
      dob: dob ?? this.dob,
      gender: gender ?? this.gender,
      civilStatus: civilStatus ?? this.civilStatus,
      category: category ?? this.category,
      email: email ?? this.email,
      contactNo: contactNo ?? this.contactNo,
      region: region ?? this.region,
      province: province ?? this.province,
      municipality: municipality ?? this.municipality,
      barangay: barangay ?? this.barangay,
      street: street ?? this.street,
      district: district ?? this.district,
      area: area ?? this.area,
      center: center ?? this.center,
      positions: positions ?? this.positions,
      membershipStatus: membershipStatus ?? this.membershipStatus,
      memberType: memberType ?? this.memberType,
      dateJoined: dateJoined ?? this.dateJoined,
      profileUrl: profileUrl ?? this.profileUrl,
      signatureUrl: signatureUrl ?? this.signatureUrl,
      signatureDeclined: signatureDeclined ?? this.signatureDeclined,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Full Name computed helper with Middle Initial (e.g. Jonathan S. Reyes)
  String get fullName {
    final fName = firstName.trim();
    final lName = lastName.trim();
    final mName = middleName.trim();

    if (mName.isNotEmpty) {
      final initial = mName[0].toUpperCase();
      return '$fName $initial. $lName'.trim();
    }
    return '$fName $lName'.trim();
  }

  /// Primary position title (single unified string)
  String get primaryRole {
    if (positions.isNotEmpty && positions.first.title.isNotEmpty) {
      return positions.first.title;
    }
    if (role.isNotEmpty && role != 'member') {
      return role;
    }
    return 'Member';
  }

  /// Alias for primaryRole
  String get primaryPosition => primaryRole;

  /// Initials derived from first name and last name
  String get initials {
    String res = '';
    if (firstName.trim().isNotEmpty) res += firstName.trim()[0].toUpperCase();
    if (lastName.trim().isNotEmpty) res += lastName.trim()[0].toUpperCase();
    return res.isNotEmpty ? res : 'U';
  }

  /// Positions formatted summary string
  String get positionsSummary {
    if (positions.isEmpty) {
      return primaryRole;
    }
    final titles = positions.map((p) => p.title).where((t) => t.isNotEmpty).toList();
    if (titles.isEmpty) return 'Member';
    return titles.join(', ');
  }

  /// Backward-compatible alias for activity check
  bool get isInactive =>
      membershipStatus.trim().toLowerCase() == 'inactive' ||
      status.trim().toLowerCase() == 'inactive';

  bool get isActive => !isInactive;

  MemberStatus get memberStatusEnum {
    if (membershipStatus.toLowerCase() == 'active' ||
        status.toLowerCase() == 'registered') {
      return MemberStatus.active;
    } else if (membershipStatus.toLowerCase() == 'pending') {
      return MemberStatus.pending;
    }
    return MemberStatus.inactive;
  }

  // --- Role & Permission Helpers (matching uecfi_pmm) ---
  bool get isAdmin => role.toLowerCase() == 'admin';
  bool get isDistrictLeader =>
      role.toLowerCase() == 'district' ||
      role.toLowerCase() == 'district_admin' ||
      role.toLowerCase() == 'district admin';
  bool get isDistrictAdmin => isAdmin || isDistrictLeader;
  bool get isAreaLeader => role.toLowerCase() == 'area';
  bool get isLocalLeader => role.toLowerCase() == 'local';
  bool get isRegularMember => role.toLowerCase() == 'member' || role.isEmpty;

  bool get canCreateDistrictPosts => isAdmin || isDistrictLeader;
  bool get canViewActivityLogs => isAdmin || isDistrictLeader;
  bool get canAddMembers => !isRegularMember;
  bool get canAssignRoles => isAdmin;
  bool get canAccessAdminTools => isAdmin || isDistrictLeader;

  // Scope locking helpers
  bool get isDistrictLocked => isDistrictLeader || isAreaLeader || isLocalLeader;
  bool get isAreaLocked => isAreaLeader || isLocalLeader;
  bool get isCenterLocked => isLocalLeader;

  String get roleDisplayName {
    switch (role.toLowerCase()) {
      case 'admin':
        return 'Administrator';
      case 'district':
      case 'district_admin':
      case 'district admin':
        return 'District Admin';
      case 'area':
        return 'Area Coordinator';
      case 'local':
        return 'Local Officer';
      case 'member':
      default:
        return 'Church Member';
    }
  }

  Color get roleColor {
    switch (role.toLowerCase()) {
      case 'admin':
        return const Color(0xFFA100FF);
      case 'district':
      case 'district_admin':
      case 'district admin':
        return const Color(0xFF00B0FF);
      case 'area':
        return const Color(0xFFFF9100);
      case 'local':
        return const Color(0xFF00C853);
      case 'member':
      default:
        return const Color(0xFF88849E);
    }
  }

  /// Normalizes name string by trimming, lowercasing, and collapsing consecutive whitespace
  static String normalizeName(String name) {
    return name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Normalized key consisting of first name, middle name, and surname (last name)
  String get duplicateNameKey {
    final f = normalizeName(firstName);
    final m = normalizeName(middleName);
    final l = normalizeName(lastName);
    return '$f|$m|$l';
  }

  /// Checks if this member has the exact same first name, middle name, and surname as another member
  bool isDuplicateNameOf(Member other) {
    if (id.isNotEmpty && other.id.isNotEmpty && id == other.id) return false;
    if (memberId.isNotEmpty && other.memberId.isNotEmpty && memberId == other.memberId) return false;

    final f1 = normalizeName(firstName);
    final f2 = normalizeName(other.firstName);
    final m1 = normalizeName(middleName);
    final m2 = normalizeName(other.middleName);
    final l1 = normalizeName(lastName);
    final l2 = normalizeName(other.lastName);

    if (f1.isEmpty || l1.isEmpty) return false;
    return f1 == f2 && m1 == m2 && l1 == l2;
  }

  /// Generates the next standardized Member ID in the format: UECFI-YYYY-0000
  static String generateNextMemberId(List<Member> existingMembers, [int? year]) {
    final currentYear = year ?? DateTime.now().year;
    final prefix = 'UECFI-$currentYear-';
    int maxSeq = 0;

    final regex = RegExp('^UECFI-$currentYear-(\\d+)\$', caseSensitive: false);

    for (final m in existingMembers) {
      final id = m.memberId.trim();
      final match = regex.firstMatch(id);
      if (match != null) {
        final num = int.tryParse(match.group(1) ?? '0') ?? 0;
        if (num > maxSeq) {
          maxSeq = num;
        }
      }
    }

    final nextSeq = maxSeq > 0
        ? maxSeq + 1
        : (existingMembers.isNotEmpty ? existingMembers.length + 1 : 1);
    final seqStr = nextSeq.toString().padLeft(4, '0');
    return '$prefix$seqStr';
  }

  /// Checks whether a member's profile is complete according to required fields
  static bool isProfileCompleteMap(Map<String, dynamic> member) {
    const requiredFields = [
      'firstName',
      'lastName',
      'middleName',
      'dob',
      'gender',
      'civilStatus',
      'contactNo',
      'region',
      'province',
      'municipality',
      'barangay',
      'district',
      'area',
      'center',
      'profileUrl',
    ];

    for (final field in requiredFields) {
      final val = member[field]?.toString().trim();
      if (val == null || val.isEmpty || val == 'N/A') {
        return false;
      }
    }

    final signatureDeclined = member['signatureDeclined'] as bool? ?? false;
    final signatureUrl = member['signatureUrl']?.toString().trim() ?? '';
    if (!signatureDeclined && signatureUrl.isEmpty) {
      return false;
    }

    final positions = member['positions'] as List?;
    if (positions == null || positions.isEmpty) {
      return false;
    }

    return true;
  }

  /// List of specific field names that are lacking in this member's profile
  List<String> get missingFields {
    final List<String> missing = [];

    if (firstName.trim().isEmpty || firstName.trim() == 'N/A') missing.add('First Name');
    if (lastName.trim().isEmpty || lastName.trim() == 'N/A') missing.add('Last Name');
    if (middleName.trim().isEmpty || middleName.trim() == 'N/A') missing.add('Middle Name');
    if (dob.trim().isEmpty || dob.trim() == 'N/A') missing.add('Date of Birth');
    if (gender.trim().isEmpty || gender.trim() == 'N/A') missing.add('Gender');
    if (civilStatus.trim().isEmpty || civilStatus.trim() == 'N/A') missing.add('Civil Status');
    if (contactNo.trim().isEmpty || contactNo.trim() == 'N/A') missing.add('Contact Number');
    if (region.trim().isEmpty || region.trim() == 'N/A') missing.add('Region');
    if (province.trim().isEmpty || province.trim() == 'N/A') missing.add('Province');
    if (municipality.trim().isEmpty || municipality.trim() == 'N/A') missing.add('Municipality');
    if (barangay.trim().isEmpty || barangay.trim() == 'N/A') missing.add('Barangay');
    if (district.trim().isEmpty || district.trim() == 'N/A') missing.add('District');
    if (area.trim().isEmpty || area.trim() == 'N/A') missing.add('Area');
    if (center.trim().isEmpty || center.trim() == 'N/A') missing.add('Local Center');
    if (profileUrl.trim().isEmpty || profileUrl.trim() == 'N/A') missing.add('Profile Photo');
    if (!signatureDeclined && signatureUrl.trim().isEmpty) missing.add('Digital Signature');
    if (positions.isEmpty) missing.add('Ministry Position');

    return missing;
  }

  /// Computed boolean check for completeness of this Member instance
  bool get isProfileComplete => missingFields.isEmpty;

  /// Image provider for profile photo supporting Network URLs and Base64 Data URLs
  ImageProvider? get profileImageProvider {
    final url = profileUrl.trim();
    if (url.isEmpty || url == 'N/A') return null;
    if (url.startsWith('data:image') || !url.startsWith('http')) {
      try {
        final raw = url.contains(',') ? url.split(',').last : url;
        return MemoryImage(base64Decode(raw));
      } catch (_) {
        return null;
      }
    }
    return CachedNetworkImageProvider(url);
  }

  /// Image provider for digital signature supporting Network URLs and Base64 Data URLs
  ImageProvider? get signatureImageProvider {
    final url = signatureUrl.trim();
    if (url.isEmpty || url == 'N/A') return null;
    if (url.startsWith('data:image') || !url.startsWith('http')) {
      try {
        final raw = url.contains(',') ? url.split(',').last : url;
        return MemoryImage(base64Decode(raw));
      } catch (_) {
        return null;
      }
    }
    return CachedNetworkImageProvider(url);
  }

  /// Parse Date of Birth into DateTime
  DateTime? get parsedDob => DateFormatter.parseDate(dob);

  /// Dynamically calculated age from DOB (auto-computed)
  int get dynamicAge => DateFormatter.calculateAge(dob);

  /// Computed age getter
  int get age => dynamicAge;

  /// Formatted date string e.g. "Jul 24, 1983 (42 years old)"
  String get formattedDobWithAge => DateFormatter.formatDobWithAge(dob);

  /// Parse Date Joined into DateTime
  DateTime? get parsedDateJoined => DateFormatter.parseDate(dateJoined);

  /// Formatted date joined string e.g. "Jul 24, 1983"
  String get formattedDateJoined => DateFormatter.formatDate(dateJoined);

  /// Automatically calculate ministry category based on age and civil status
  static String calculateCategory({
    required int age,
    required String civilStatus,
  }) {
    final isSingle = civilStatus.trim().toLowerCase() == 'single';

    if (!isSingle || age >= 31) {
      return 'Adult';
    } else if (age >= 18 && age <= 30) {
      return 'FYS';
    } else {
      return 'Kiddies';
    }
  }

  /// Dynamically calculated ministry category from age & civil status
  String get dynamicCategory => calculateCategory(
        age: dynamicAge,
        civilStatus: civilStatus,
      );

  /// Fee Assessment Rate per Member:
  /// Adult (31+ or Married) - Old: ₱172, New: ₱202
  /// FYS (Single, 18-30 yrs) - Old: ₱172, New: ₱202
  /// Kiddies (17 yrs & below) - Old: ₱100, New: ₱130
  /// Inactive Members - ₱0 (Excluded from fee assessment)
  static double calculateMemberRate({
    required String category,
    required String memberType,
    required String membershipStatus,
    required String status,
  }) {
    final isInactive = membershipStatus.trim().toLowerCase() == 'inactive' ||
        status.trim().toLowerCase() == 'inactive';
    if (isInactive) {
      return 0.0;
    }

    final isNew = memberType.trim().toLowerCase() == 'new';
    final normalizedCat = category.trim().toLowerCase();

    if (normalizedCat == 'kiddies') {
      return isNew ? 130.0 : 100.0;
    } else {
      // Adult or FYS
      return isNew ? 202.0 : 172.0;
    }
  }

  /// Computed fee assessment rate for this member instance
  double get assessmentRate => calculateMemberRate(
        category: dynamicCategory,
        memberType: memberType,
        membershipStatus: membershipStatus,
        status: status,
      );

  factory Member.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Member.fromMap(data, id: doc.id);
  }

  factory Member.fromMap(Map<String, dynamic> map, {String? id}) {
    List<MemberPosition> parsedPositions = [];
    if (map['positions'] is List) {
      parsedPositions = (map['positions'] as List)
          .map((p) => MemberPosition.fromDynamic(p))
          .toList();
    }

    return Member(
      id: id ?? map['id']?.toString() ?? map['memberId']?.toString() ?? '',
      memberId: map['memberId']?.toString() ?? '00001',
      uid: map['uid']?.toString() ?? '',
      role: map['role']?.toString() ?? 'member',
      status: map['status']?.toString() ?? 'registered',
      firstName: map['firstName']?.toString() ?? '',
      middleName: map['middleName']?.toString() ?? '',
      lastName: map['lastName']?.toString() ?? '',
      dob: map['dob']?.toString() ?? '',
      gender: map['gender']?.toString() ?? 'Male',
      civilStatus: map['civilStatus']?.toString() ?? 'Single',
      category: map['category']?.toString() ?? 'Adult',
      email: map['email']?.toString() ?? '',
      contactNo: map['contactNo']?.toString() ??
          map['contactNumber']?.toString() ??
          '',
      region: map['region']?.toString() ?? '',
      province: map['province']?.toString() ?? '',
      municipality: map['municipality']?.toString() ?? '',
      barangay: map['barangay']?.toString() ?? '',
      street: map['street']?.toString() ?? '',
      district: map['district']?.toString() ?? 'District 3',
      area: map['area']?.toString() ?? 'Area 1',
      center: map['center']?.toString() ??
          map['churchBranch']?.toString() ??
          'Antipolo Center',
      positions: parsedPositions,
      membershipStatus: map['membershipStatus']?.toString() ?? 'Active',
      memberType: map['memberType']?.toString() ?? 'Old',
      dateJoined: map['dateJoined']?.toString() ?? '',
      profileUrl: map['profileUrl']?.toString() ?? '',
      signatureUrl: map['signatureUrl']?.toString() ?? '',
      signatureDeclined: map['signatureDeclined'] == true,
      createdAt: map['createdAt']?.toString() ?? '',
      updatedAt: map['updatedAt']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'memberId': memberId,
      'uid': uid,
      'role': role,
      'status': status,
      'firstName': firstName,
      'middleName': middleName,
      'lastName': lastName,
      'dob': dob,
      'gender': gender,
      'civilStatus': civilStatus,
      'category': category,
      'email': email,
      'contactNo': contactNo,
      'region': region,
      'province': province,
      'municipality': municipality,
      'barangay': barangay,
      'street': street,
      'district': district,
      'area': area,
      'center': center,
      'positions': positions.map((p) => p.toMap()).toList(),
      'membershipStatus': membershipStatus,
      'memberType': memberType,
      'dateJoined': dateJoined,
      'profileUrl': profileUrl,
      'signatureUrl': signatureUrl,
      'signatureDeclined': signatureDeclined,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
