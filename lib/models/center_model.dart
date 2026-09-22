import 'member.dart';

class CenterModel {
  final int id;
  final String centerName;
  final String centerAddress;
  final String district;
  final String area;

  // Center Financial Obligations Constants (3-Year Term)
  static const double certificateOfAffiliationFee = 300.0;
  static const double yearlyFee = 780.0;
  static const double totalCenterObligation = 1080.0; // ₱300 + ₱780

  const CenterModel({
    required this.id,
    required this.centerName,
    this.centerAddress = '',
    required this.district,
    required this.area,
  });

  /// Formatted name with address when disambiguation is needed
  String get displayNameWithAddress => centerAddress.trim().isNotEmpty
      ? '$centerName (${centerAddress.trim()})'
      : centerName;

  /// Checks if a member belongs to this specific center, with strict
  /// district and area scoping so centers with the same name across
  /// different areas or addresses are never conflated.
  bool matchesMember(Member m, List<CenterModel> allCenters) {
    final mCenter = m.center.trim().toLowerCase();
    final cName = centerName.trim().toLowerCase();
    final cDisplay = displayNameWithAddress.trim().toLowerCase();
    final cAddr = centerAddress.trim().toLowerCase();
    final mArea = m.area.trim().toLowerCase();
    final cArea = area.trim().toLowerCase();
    final mDistrict = m.district.trim().toLowerCase();
    final cDistrict = district.trim().toLowerCase();

    if (mCenter.isEmpty) return false;

    // 1. Strict District Check: if both have district, they MUST match
    if (mDistrict.isNotEmpty && cDistrict.isNotEmpty && mDistrict != cDistrict) {
      return false;
    }

    // 2. Strict Area Check: if both have area, they MUST match!
    // Centers with the same center name in different areas are NOT the same.
    if (mArea.isNotEmpty && cArea.isNotEmpty && mArea != cArea) {
      return false;
    }

    // 3. Exact match with display name including address
    if (mCenter == cDisplay) return true;

    // 4. Exact match with center name
    if (mCenter == cName) {
      final hasSameNameSiblings = allCenters.any(
        (other) =>
            other.id != id &&
            other.centerName.trim().toLowerCase() == cName &&
            (other.area.trim().toLowerCase() != cArea ||
                other.centerAddress.trim().toLowerCase() != cAddr),
      );

      if (hasSameNameSiblings) {
        // If member has an area specified, it must match this center's area
        if (mArea.isNotEmpty && cArea.isNotEmpty) {
          return mArea == cArea;
        }

        // If member has no area recorded, disambiguate with specific municipality/barangay
        if (cAddr.isNotEmpty &&
            (m.municipality.trim().isNotEmpty ||
                m.barangay.trim().isNotEmpty)) {
          final mLoc = '${m.barangay} ${m.municipality}'.toLowerCase();
          final addrParts = cAddr
              .split(',')
              .map((p) => p.trim())
              .where((p) => p.isNotEmpty && p.toLowerCase() != 'cagayan')
              .toList();
          if (addrParts.any((part) => mLoc.contains(part.toLowerCase()))) {
            return true;
          }
        }

        // Do not conflate across duplicate centers if area/address doesn't confirm
        return false;
      }

      return true;
    }

    // 5. Member center string contains both center name and center address
    if (cAddr.isNotEmpty &&
        mCenter.contains(cName) &&
        mCenter.contains(cAddr)) {
      return true;
    }

    return false;
  }

  factory CenterModel.fromMap(Map<String, dynamic> map) {
    return CenterModel(
      id: int.tryParse(map['id']?.toString() ?? '0') ?? 0,
      centerName: map['centername']?.toString() ??
          map['centerName']?.toString() ??
          map['name']?.toString() ??
          '',
      centerAddress: map['centeraddress']?.toString() ??
          map['centerAddress']?.toString() ??
          map['address']?.toString() ??
          '',
      district: map['district']?.toString() ??
          map['District']?.toString() ??
          'District 3',
      area: map['area']?.toString() ?? map['Area']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'centername': centerName,
      'centeraddress': centerAddress,
      'district': district,
      'area': area,
    };
  }
}
