import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/center_model.dart';
import '../../models/member.dart';
import '../../services/database_service.dart';
import '../../services/firestore_service.dart';
import '../centers/center_details_screen.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final DatabaseService _databaseService = DatabaseService();

  final NumberFormat _wholeCurrencyFormat = NumberFormat('#,##0', 'en_US');
  final NumberFormat _countFormat = NumberFormat('#,##0', 'en_US');

  final TextEditingController _searchController = TextEditingController();
  String _centerSearchQuery = '';

  String _selectedDistrict = 'All Districts';
  String _selectedArea = 'All Areas';
  String _selectedCenter = 'All Local Centers';

  List<CenterModel> _databaseCenters = [];
  bool _isLoadingCenters = true;
  Member? _currentMember;

  @override
  void initState() {
    super.initState();
    _loadCenters();
    _firestoreService.getCurrentMember().then((user) {
      if (mounted && user != null) {
        setState(() {
          _currentMember = user;
          if (user.isDistrictLocked && user.district.isNotEmpty) {
            _selectedDistrict = user.district;
          }
          if (user.isAreaLocked && user.area.isNotEmpty) {
            _selectedArea = user.area;
          }
          if (user.isCenterLocked && user.center.isNotEmpty) {
            _selectedCenter = user.center;
          }
        });
      }
    }).catchError((_) {});
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCenters() async {
    try {
      final centers = await _databaseService.getCenters();
      if (mounted) {
        setState(() {
          _databaseCenters = centers;
          _isLoadingCenters = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingCenters = false;
        });
      }
    }
  }

  bool get _hasActiveFilter =>
      _selectedDistrict != 'All Districts' ||
      _selectedArea != 'All Areas' ||
      _selectedCenter != 'All Local Centers';

  void _resetFilters() {
    setState(() {
      final user = _currentMember;
      _selectedDistrict = (user != null && user.isDistrictLocked && user.district.isNotEmpty)
          ? user.district
          : 'All Districts';
      _selectedArea = (user != null && user.isAreaLocked && user.area.isNotEmpty)
          ? user.area
          : 'All Areas';
      _selectedCenter = (user != null && user.isCenterLocked && user.center.isNotEmpty)
          ? user.center
          : 'All Local Centers';
    });
  }

  /// Center-Member matching with strict area and district isolation
  List<Member> _getCenterMembers(
    CenterModel center,
    List<Member> baseMembers,
    List<CenterModel> allCenters,
  ) {
    return baseMembers.where((m) => center.matchesMember(m, allCenters)).toList();
  }

  void _showRateScheduleModal(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final cardBg = isDark ? const Color(0xFF16161F) : Colors.white;
    final textPrimary = isDark ? const Color(0xFFF5F5FA) : const Color(0xFF0E0E14);
    final textSecondary = isDark ? const Color(0xFF9E9EAF) : const Color(0xFF6E6E82);
    final borderColor = isDark ? const Color(0xFF262633) : const Color(0xFFE5E5ED);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: isDark ? 0.22 : 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.receipt_long_rounded,
                        color: primaryColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'FEE & OBLIGATIONS SCHEDULE',
                          style: TextStyle(
                            color: primaryColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Official Financial Assessments',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(color: borderColor),
                const SizedBox(height: 12),

                // 1. Member Assessment Rates
                Text(
                  '1. MEMBER ASSESSMENT RATES (ANNUAL)',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 12),
                _buildRateRow(
                  context,
                  title: 'Adult (31+ or Married)',
                  oldRate: '₱172',
                  newRate: '₱202',
                ),
                Divider(color: borderColor, height: 16),
                _buildRateRow(
                  context,
                  title: 'FYS (Single, 18–30 yrs)',
                  oldRate: '₱172',
                  newRate: '₱202',
                ),
                Divider(color: borderColor, height: 16),
                _buildRateRow(
                  context,
                  title: 'Kiddies (17 yrs & below)',
                  oldRate: '₱100',
                  newRate: '₱130',
                ),
                Divider(color: borderColor, height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Inactive Members',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textSecondary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '₱0 (Excluded)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                Divider(color: borderColor),
                const SizedBox(height: 12),

                // 2. Center Financial Obligations
                Text(
                  '2. CENTER OBLIGATIONS (FOR 3 YEARS)',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 12),
                _buildObligationRow(
                  'Certificate of Affiliation',
                  '₱${_wholeCurrencyFormat.format(CenterModel.certificateOfAffiliationFee)}',
                  context,
                ),
                Divider(color: borderColor, height: 16),
                _buildObligationRow(
                  'Yearly Center Fee',
                  '₱${_wholeCurrencyFormat.format(CenterModel.yearlyFee)}',
                  context,
                ),
                Divider(color: borderColor, height: 16),
                _buildObligationRow(
                  'Total per Center (3 Years)',
                  '₱${_wholeCurrencyFormat.format(CenterModel.totalCenterObligation)}',
                  context,
                  isHighlight: true,
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRateRow(
    BuildContext context, {
    required String title,
    required String oldRate,
    required String newRate,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final textPrimary = isDark ? const Color(0xFFF5F5FA) : const Color(0xFF0E0E14);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
        ),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Old: $oldRate',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: isDark ? 0.22 : 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'New: $newRate',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: primaryColor,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildObligationRow(
    String title,
    String amount,
    BuildContext context, {
    bool isHighlight = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final textPrimary = isDark ? const Color(0xFFF5F5FA) : const Color(0xFF0E0E14);
    final textSecondary = isDark ? const Color(0xFF9E9EAF) : const Color(0xFF6E6E82);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: isHighlight ? FontWeight.w700 : FontWeight.w500,
            color: isHighlight ? primaryColor : textSecondary,
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isHighlight ? primaryColor : textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricItem({
    required BuildContext context,
    required String label,
    required double amount,
    required int count,
    required String unit,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? const Color(0xFFF5F5FA) : const Color(0xFF0E0E14);
    final textSecondary = isDark ? const Color(0xFF9E9EAF) : const Color(0xFF6E6E82);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          amount > 0 ? '₱${_wholeCurrencyFormat.format(amount)}' : '₱0',
          style: TextStyle(
            color: textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${_countFormat.format(count)} $unit',
          style: TextStyle(
            color: textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  void _showFilterModal(BuildContext context, List<CenterModel> allCenters) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final cardBg = isDark ? const Color(0xFF16161F) : Colors.white;

    final isDistrictLocked = _currentMember?.isDistrictLocked ?? false;
    final isAreaLocked = _currentMember?.isAreaLocked ?? false;
    final isCenterLocked = _currentMember?.isCenterLocked ?? false;

    final districts = (isDistrictLocked && _currentMember != null)
        ? [_currentMember!.district]
        : [
            'All Districts',
            ...{for (final c in allCenters) if (c.district.isNotEmpty) c.district},
          ];

    showModalBottomSheet(
      context: context,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        String tempDistrict = _selectedDistrict;
        String tempArea = _selectedArea;
        String tempCenter = _selectedCenter;

        return StatefulBuilder(
          builder: (context, setModalState) {
            final availableAreas = (isAreaLocked && _currentMember != null)
                ? [_currentMember!.area]
                : [
                    'All Areas',
                    ...{
                      for (final c in allCenters)
                        if (c.area.isNotEmpty &&
                            (tempDistrict == 'All Districts' ||
                                c.district.toLowerCase() == tempDistrict.toLowerCase()))
                          c.area,
                    },
                  ];

            final availableCenters = (isCenterLocked && _currentMember != null)
                ? [_currentMember!.center]
                : [
                    'All Local Centers',
                    ...{
                      for (final c in allCenters)
                        if ((tempDistrict == 'All Districts' ||
                                c.district.toLowerCase() ==
                                    tempDistrict.toLowerCase()) &&
                            (tempArea == 'All Areas' ||
                                c.area.toLowerCase() == tempArea.toLowerCase()))
                          c.displayNameWithAddress,
                    },
                  ];

            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Filter Finance Scope',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (tempDistrict != 'All Districts' ||
                            tempArea != 'All Areas' ||
                            tempCenter != 'All Local Centers')
                          TextButton(
                            onPressed: () {
                              setModalState(() {
                                final user = _currentMember;
                                tempDistrict = (user != null && user.isDistrictLocked && user.district.isNotEmpty)
                                    ? user.district
                                    : 'All Districts';
                                tempArea = (user != null && user.isAreaLocked && user.area.isNotEmpty)
                                    ? user.area
                                    : 'All Areas';
                                tempCenter = (user != null && user.isCenterLocked && user.center.isNotEmpty)
                                    ? user.center
                                    : 'All Local Centers';
                              });
                            },
                            child: const Text('Reset'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // District Dropdown
                    const Text(
                      'DISTRICT',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 46,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E2A) : const Color(0xFFF2F2F7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? const Color(0xFF2E2E3E) : const Color(0xFFE2E2EA),
                          width: 1.1,
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: districts.contains(tempDistrict)
                              ? tempDistrict
                              : districts.first,
                          isExpanded: true,
                          dropdownColor: isDark ? const Color(0xFF16161F) : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          icon: Icon(
                            isDistrictLocked ? Icons.lock_outline_rounded : Icons.keyboard_arrow_down_rounded,
                            size: isDistrictLocked ? 16 : 22,
                            color: isDistrictLocked ? Colors.grey : null,
                          ),
                          items: districts
                              .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                              .toList(),
                          onChanged: isDistrictLocked
                              ? null
                              : (val) {
                                  if (val != null) {
                                    setModalState(() {
                                      tempDistrict = val;
                                      tempArea = 'All Areas';
                                      tempCenter = 'All Local Centers';
                                    });
                                  }
                                },
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Area Dropdown
                    const Text(
                      'AREA',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 46,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E2A) : const Color(0xFFF2F2F7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? const Color(0xFF2E2E3E) : const Color(0xFFE2E2EA),
                          width: 1.1,
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: availableAreas.contains(tempArea)
                              ? tempArea
                              : availableAreas.first,
                          isExpanded: true,
                          dropdownColor: isDark ? const Color(0xFF16161F) : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          icon: Icon(
                            isAreaLocked ? Icons.lock_outline_rounded : Icons.keyboard_arrow_down_rounded,
                            size: isAreaLocked ? 16 : 22,
                            color: isAreaLocked ? Colors.grey : null,
                          ),
                          items: availableAreas
                              .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                              .toList(),
                          onChanged: isAreaLocked
                              ? null
                              : (val) {
                                  if (val != null) {
                                    setModalState(() {
                                      tempArea = val;
                                      tempCenter = 'All Local Centers';
                                    });
                                  }
                                },
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Local Center Dropdown
                    const Text(
                      'LOCAL CENTER',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 46,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E2A) : const Color(0xFFF2F2F7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? const Color(0xFF2E2E3E) : const Color(0xFFE2E2EA),
                          width: 1.1,
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: availableCenters.contains(tempCenter)
                              ? tempCenter
                              : availableCenters.first,
                          isExpanded: true,
                          dropdownColor: isDark ? const Color(0xFF16161F) : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          icon: Icon(
                            isCenterLocked ? Icons.lock_outline_rounded : Icons.keyboard_arrow_down_rounded,
                            size: isCenterLocked ? 16 : 22,
                            color: isCenterLocked ? Colors.grey : null,
                          ),
                          items: availableCenters
                              .map(
                                (c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(
                                    c,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: isCenterLocked
                              ? null
                              : (val) {
                                  if (val != null) {
                                    setModalState(() {
                                      tempCenter = val;
                                    });
                                  }
                                },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Apply Button
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () {
                          setState(() {
                            _selectedDistrict = tempDistrict;
                            _selectedArea = tempArea;
                            _selectedCenter = tempCenter;
                          });
                          Navigator.of(ctx).pop();
                        },
                        child: const Text(
                          'Apply Filter',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
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

    return Scaffold(
      body: StreamBuilder<List<Member>>(
        stream: _firestoreService.getMembersStream(),
        builder: (context, snapshot) {
          final allMembers = snapshot.data ?? [];

          // 1. Official centers from SQLite
          final allCenters = List<CenterModel>.from(_databaseCenters);

          // 2. Scoped Centers by District / Area / Center filter
          final scopedCenters = allCenters.where((c) {
            final matchDistrict = _selectedDistrict == 'All Districts' ||
                c.district.toLowerCase() == _selectedDistrict.toLowerCase();
            final matchArea = _selectedArea == 'All Areas' ||
                c.area.toLowerCase() == _selectedArea.toLowerCase();
            final matchCenter = _selectedCenter == 'All Local Centers' ||
                c.centerName.toLowerCase() == _selectedCenter.toLowerCase() ||
                c.displayNameWithAddress.toLowerCase() ==
                    _selectedCenter.toLowerCase();
            return matchDistrict && matchArea && matchCenter;
          }).toList();

          // 3. Active members in current scope (inactive excluded from fee assessments)
          final baseMembers = allMembers.where((m) {
            if (m.isInactive) return false;

            final matchDistrict = _selectedDistrict == 'All Districts' ||
                m.district.toLowerCase() == _selectedDistrict.toLowerCase();
            final matchArea = _selectedArea == 'All Areas' ||
                m.area.toLowerCase() == _selectedArea.toLowerCase();
            final matchCenter = _selectedCenter == 'All Local Centers' ||
                m.center.toLowerCase() == _selectedCenter.toLowerCase() ||
                _selectedCenter.toLowerCase().contains(m.center.toLowerCase()) ||
                m.center.toLowerCase().contains(_selectedCenter.toLowerCase());
            return matchDistrict && matchArea && matchCenter;
          }).toList();

          // 4. Member Financial Calculations
          double totalMemberDues = 0.0;
          int adultCount = 0;
          double adultTotal = 0.0;
          int fysCount = 0;
          double fysTotal = 0.0;
          int kiddiesCount = 0;
          double kiddiesTotal = 0.0;

          for (final m in baseMembers) {
            final rate = m.assessmentRate;
            totalMemberDues += rate;

            final cat = m.dynamicCategory.toLowerCase();
            if (cat == 'adult') {
              adultCount++;
              adultTotal += rate;
            } else if (cat == 'fys') {
              fysCount++;
              fysTotal += rate;
            } else if (cat == 'kiddies') {
              kiddiesCount++;
              kiddiesTotal += rate;
            }
          }

          // 5. Center Financial Obligations (3 Years)
          final int totalCentersCount = scopedCenters.length;
          final double totalCenterObligations =
              totalCentersCount * CenterModel.totalCenterObligation;
          final double grandTotalDues = totalMemberDues + totalCenterObligations;

          // 6. Filter centers for the list based on search query
          final filteredCenters = scopedCenters.where((center) {
            if (_centerSearchQuery.isNotEmpty) {
              final q = _centerSearchQuery.toLowerCase();
              final matches = center.centerName.toLowerCase().contains(q) ||
                  center.centerAddress.toLowerCase().contains(q) ||
                  center.area.toLowerCase().contains(q) ||
                  center.district.toLowerCase().contains(q);
              if (!matches) return false;
            }
            return true;
          }).toList()
            ..sort((a, b) {
              final nameComp = a.centerName
                  .toLowerCase()
                  .compareTo(b.centerName.toLowerCase());
              if (nameComp != 0) return nameComp;
              return a.centerAddress
                  .toLowerCase()
                  .compareTo(b.centerAddress.toLowerCase());
            });

          return CustomScrollView(
            slivers: [
              // Header Section & Assessed Financial Dues Card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ASSESSED FINANCIAL DUES Hero Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: borderColor, width: 1.2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: isDark ? 0.25 : 0.03,
                              ),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header Title Row: Assessed Financial dues + Info button
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _selectedCenter != 'All Local Centers'
                                            ? '$_selectedCenter Assessed Financial dues'
                                            : (_selectedDistrict != 'All Districts'
                                                ? '$_selectedDistrict Assessed Financial dues'
                                                : 'Assessed Financial dues'),
                                        style: TextStyle(
                                          color: primaryColor,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.8,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 6),
                                      // Total Payment below title
                                      Text(
                                        '₱${_wholeCurrencyFormat.format(grandTotalDues)}',
                                        style: TextStyle(
                                          color: textPrimary,
                                          fontSize: 26,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.info_outline_rounded,
                                    color: primaryColor,
                                    size: 22,
                                  ),
                                  tooltip: 'Fee & Obligations Schedule',
                                  onPressed: () =>
                                      _showRateScheduleModal(context),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Divider(color: borderColor, height: 1),
                            const SizedBox(height: 14),

                            // Member Dues, Center Obligations
                            Row(
                              children: [
                                Expanded(
                                  child: _buildMetricItem(
                                    context: context,
                                    label: 'Member Dues',
                                    amount: totalMemberDues,
                                    count: baseMembers.length,
                                    unit: 'active members',
                                    color: primaryColor,
                                  ),
                                ),
                                Container(
                                  height: 40,
                                  width: 1,
                                  color: borderColor,
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 8),
                                ),
                                Expanded(
                                  child: _buildMetricItem(
                                    context: context,
                                    label: 'Center Obligations',
                                    amount: totalCenterObligations,
                                    count: totalCentersCount,
                                    unit: 'centers (3 yrs)',
                                    color: primaryColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Divider(color: borderColor, height: 1),
                            const SizedBox(height: 14),

                            // Adults, Fys, Kiddies
                            Row(
                              children: [
                                Expanded(
                                  child: _buildMetricItem(
                                    context: context,
                                    label: 'Adults',
                                    amount: adultTotal,
                                    count: adultCount,
                                    unit: 'members',
                                    color: const Color(0xFF00C853),
                                  ),
                                ),
                                Container(
                                  height: 40,
                                  width: 1,
                                  color: borderColor,
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 4),
                                ),
                                Expanded(
                                  child: _buildMetricItem(
                                    context: context,
                                    label: 'FYS',
                                    amount: fysTotal,
                                    count: fysCount,
                                    unit: 'members',
                                    color: Colors.amber.shade800,
                                  ),
                                ),
                                Container(
                                  height: 40,
                                  width: 1,
                                  color: borderColor,
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 4),
                                ),
                                Expanded(
                                  child: _buildMetricItem(
                                    context: context,
                                    label: 'Kiddies',
                                    amount: kiddiesTotal,
                                    count: kiddiesCount,
                                    unit: 'members',
                                    color: primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Section Title: Local Church Centers Assessments & Active Filters
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'LOCAL CHURCH ASSESSMENTS',
                            style: TextStyle(
                              color: primaryColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                '${filteredCenters.length} Centers',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: textSecondary,
                                ),
                              ),
                              if (_hasActiveFilter) ...[
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: _resetFilters,
                                  child: Text(
                                    'Clear',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: primaryColor,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Search Input & Filter Button
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: cardBg,
                                borderRadius: BorderRadius.circular(14),
                                border:
                                    Border.all(color: borderColor, width: 1.1),
                              ),
                              child: TextField(
                                controller: _searchController,
                                onChanged: (val) {
                                  setState(() {
                                    _centerSearchQuery = val.trim();
                                  });
                                },
                                decoration: InputDecoration(
                                  hintText: 'Search center name or address...',
                                  hintStyle: TextStyle(
                                    color: textSecondary.withValues(alpha: 0.7),
                                    fontSize: 13.5,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.search_rounded,
                                    color: textSecondary,
                                    size: 20,
                                  ),
                                  suffixIcon: _centerSearchQuery.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear, size: 18),
                                          onPressed: () {
                                            _searchController.clear();
                                            setState(() {
                                              _centerSearchQuery = '';
                                            });
                                          },
                                        )
                                      : null,
                                  border: InputBorder.none,
                                  contentPadding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Jurisdiction Filter Button
                          InkWell(
                            onTap: () => _showFilterModal(context, allCenters),
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              height: 48,
                              width: 48,
                              decoration: BoxDecoration(
                                color: _hasActiveFilter
                                    ? primaryColor.withValues(
                                        alpha: isDark ? 0.22 : 0.12,
                                      )
                                    : cardBg,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: _hasActiveFilter
                                      ? primaryColor
                                      : borderColor,
                                  width: 1.1,
                                ),
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Icon(
                                    Icons.tune_rounded,
                                    color: _hasActiveFilter
                                        ? primaryColor
                                        : textSecondary,
                                    size: 20,
                                  ),
                                  if (_hasActiveFilter)
                                    Positioned(
                                      top: 9,
                                      right: 9,
                                      child: Container(
                                        width: 7,
                                        height: 7,
                                        decoration: BoxDecoration(
                                          color: primaryColor,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Centers List Loading State
              if (_isLoadingCenters)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                )
              // Empty State
              else if (filteredCenters.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 44,
                            color: textSecondary.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _centerSearchQuery.isNotEmpty
                                ? 'No centers match "$_centerSearchQuery"'
                                : 'No local centers recorded',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Try searching with a different keyword or reset filters.',
                            style: TextStyle(
                              fontSize: 13,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              // Centers Assessments List
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final center = filteredCenters[index];

                      // Active members in this center
                      final centerMembers = _getCenterMembers(
                        center,
                        baseMembers,
                        allCenters,
                      );

                      double centerMemberDues = 0.0;
                      for (final m in centerMembers) {
                        centerMemberDues += m.assessmentRate;
                      }

                      final double centerObligation =
                          CenterModel.totalCenterObligation;
                      final double centerTotalAssessed =
                          centerMemberDues + centerObligation;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderColor, width: 1.1),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: isDark ? 0.20 : 0.02,
                              ),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => CenterDetailsScreen(
                                    center: center,
                                    allCenters: allCenters,
                                  ),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              child: Row(
                                children: [
                                  // Center Info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          center.centerName,
                                          style: TextStyle(
                                            fontSize: 15.5,
                                            fontWeight: FontWeight.bold,
                                            color: textPrimary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          center.centerAddress.trim().isNotEmpty
                                              ? center.centerAddress.trim()
                                              : (center.area.isNotEmpty
                                                  ? '${center.district} • ${center.area}'
                                                  : 'Local Center on file'),
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            color: textSecondary,
                                            height: 1.3,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${center.area.isNotEmpty ? "${center.area} • " : ""}${_countFormat.format(centerMembers.length)} active ${centerMembers.length == 1 ? "member" : "members"}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: primaryColor.withValues(
                                              alpha: 0.85,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 14),

                                  // Total Assessed Currency
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '₱${_wholeCurrencyFormat.format(centerTotalAssessed)}',
                                        style: const TextStyle(
                                          fontSize: 16.5,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF00C853),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '₱${_wholeCurrencyFormat.format(centerMemberDues)} + ₱${_wholeCurrencyFormat.format(centerObligation)}',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                          color: textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }, childCount: filteredCenters.length),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
