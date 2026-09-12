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
