import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/center_model.dart';
import '../models/member.dart';
import '../services/database_service.dart';
import '../services/firestore_service.dart';
import 'member_details_screen.dart';

class CenterDetailsScreen extends StatefulWidget {
  final CenterModel center;
  final List<CenterModel>? allCenters;

  const CenterDetailsScreen({
    super.key,
    required this.center,
    this.allCenters,
  });

  @override
  State<CenterDetailsScreen> createState() => _CenterDetailsScreenState();
}

class _CenterDetailsScreenState extends State<CenterDetailsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final DatabaseService _databaseService = DatabaseService();

  final NumberFormat _wholeCurrencyFormat = NumberFormat('#,##0', 'en_US');
  final NumberFormat _countFormat = NumberFormat('#,##0', 'en_US');

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Filter States: Old, New, Incomplete, Complete, Active, Inactive, Adult, FYS, Kiddies
  String _selectedType = 'All'; // 'All', 'Old', 'New'
  String _selectedCompleteness = 'All'; // 'All', 'Complete', 'Incomplete'
  String _selectedStatus = 'All'; // 'All', 'Active', 'Inactive'
  String _selectedCategory = 'All'; // 'All', 'Adult', 'FYS', 'Kiddies'

  int get _activeFilterCount {
    int count = 0;
    if (_selectedType != 'All') count++;
    if (_selectedCompleteness != 'All') count++;
    if (_selectedStatus != 'All') count++;
    if (_selectedCategory != 'All') count++;
    return count;
  }

  bool get _hasActiveFilter => _activeFilterCount > 0;

  void _resetAllFilters() {
    setState(() {
      _selectedType = 'All';
      _selectedCompleteness = 'All';
      _selectedStatus = 'All';
      _selectedCategory = 'All';
    });
  }

  List<CenterModel> _allCenters = [];

  @override
  void initState() {
    super.initState();
    if (widget.allCenters != null && widget.allCenters!.isNotEmpty) {
      _allCenters = widget.allCenters!;
    } else {
      _loadCenters();
    }
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
          _allCenters = centers;
        });
      }
    } catch (_) {}
  }

  bool _memberBelongsToCenter(
    Member m,
    CenterModel center,
    List<CenterModel> allCenters,
  ) {
    final mCenter = m.center.trim().toLowerCase();
    final cName = center.centerName.trim().toLowerCase();
    final cDisplay = center.displayNameWithAddress.trim().toLowerCase();
    final cAddr = center.centerAddress.trim().toLowerCase();

    if (mCenter.isEmpty) return false;

    // 1. Exact match with display name including address
    if (mCenter == cDisplay) return true;

    // 2. Exact match with center name
    if (mCenter == cName) {
      final hasSameNameSiblings = allCenters
          .where(
            (other) =>
                other.centerName.trim().toLowerCase() == cName &&
                (other.centerAddress.trim().toLowerCase() != cAddr ||
                    other.area.trim().toLowerCase() !=
                        center.area.trim().toLowerCase()),
          )
          .isNotEmpty;

      if (hasSameNameSiblings) {
        if (m.area.trim().isNotEmpty && center.area.trim().isNotEmpty) {
          if (m.area.trim().toLowerCase() == center.area.trim().toLowerCase()) {
            return true;
          }
        }
        if (cAddr.isNotEmpty &&
            (m.municipality.trim().isNotEmpty ||
                m.province.trim().isNotEmpty ||
                m.barangay.trim().isNotEmpty)) {
          final mLoc = '${m.barangay} ${m.municipality} ${m.province}'
              .toLowerCase();
          if (cAddr.split(',').any((part) {
            final p = part.trim();
            return p.isNotEmpty && mLoc.contains(p);
          })) {
            return true;
          }
        }
        if (m.district.trim().isNotEmpty &&
            center.district.trim().isNotEmpty &&
            m.district.trim().toLowerCase() ==
                center.district.trim().toLowerCase()) {
          final sameDistrictSiblings = allCenters
              .where(
                (other) =>
                    other.centerName.trim().toLowerCase() == cName &&
                    other.district.trim().toLowerCase() ==
                        center.district.trim().toLowerCase() &&
                    (other.centerAddress.trim().toLowerCase() != cAddr ||
                        other.area.trim().toLowerCase() !=
                            center.area.trim().toLowerCase()),
              )
              .isNotEmpty;
          if (!sameDistrictSiblings) return true;
        }
        return false;
      }
      return true;
    }

    // 3. String contains both name and address
    if (cAddr.isNotEmpty &&
        mCenter.contains(cName) &&
        mCenter.contains(cAddr)) {
      return true;
    }

    return false;
  }

  Widget _buildModalSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildModalChoiceChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required Color primaryColor,
    required bool isDark,
    Color? accentColor,
    int? count,
  }) {
    final borderColor = isDark ? const Color(0xFF2E2E3E) : const Color(0xFFE5E5ED);
    final textPrimary = isDark ? const Color(0xFFF5F5FA) : const Color(0xFF0E0E14);
    final textSecondary = isDark ? const Color(0xFF9E9EAF) : const Color(0xFF6E6E82);
    final cardBg = isDark ? const Color(0xFF1E1E2A) : Colors.white;
    final effectiveColor = accentColor ?? primaryColor;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? effectiveColor.withValues(alpha: isDark ? 0.25 : 0.12)
              : cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? effectiveColor : borderColor,
            width: isSelected ? 1.4 : 1.1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? effectiveColor : textPrimary,
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? effectiveColor.withValues(alpha: 0.2)
                      : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? effectiveColor : textSecondary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _openFilterBottomSheet(BuildContext context, List<Member> centerMembers) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final textPrimary = isDark ? const Color(0xFFF5F5FA) : const Color(0xFF0E0E14);
    final textSecondary = isDark ? const Color(0xFF9E9EAF) : const Color(0xFF6E6E82);
    final cardBg = isDark ? const Color(0xFF1E1E2A) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2E2E3E) : const Color(0xFFE5E5ED);

    final oldCount = centerMembers.where((m) => m.memberType.trim().toLowerCase() == 'old').length;
    final newCount = centerMembers.where((m) => m.memberType.trim().toLowerCase() == 'new').length;
    final completeCount = centerMembers.where((m) => m.isProfileComplete).length;
    final incompleteCount = centerMembers.where((m) => !m.isProfileComplete).length;
    final activeCount = centerMembers.where((m) => !m.isInactive).length;
    final inactiveCount = centerMembers.where((m) => m.isInactive).length;
    final adultCount = centerMembers.where((m) => m.dynamicCategory.toLowerCase() == 'adult' || m.category.toLowerCase() == 'adult').length;
    final fysCount = centerMembers.where((m) => m.dynamicCategory.toLowerCase() == 'fys' || m.category.toLowerCase() == 'fys').length;
    final kiddiesCount = centerMembers.where((m) => m.dynamicCategory.toLowerCase() == 'kiddies' || m.category.toLowerCase() == 'kiddies').length;

    String tempType = _selectedType;
    String tempCompleteness = _selectedCompleteness;
    String tempStatus = _selectedStatus;
    String tempCategory = _selectedCategory;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalCtx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final tempActiveCount = (tempType != 'All' ? 1 : 0) +
              (tempCompleteness != 'All' ? 1 : 0) +
              (tempStatus != 'All' ? 1 : 0) +
              (tempCategory != 'All' ? 1 : 0);

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
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
                      Row(
                        children: [
                          Icon(Icons.tune_rounded, size: 22, color: primaryColor),
                          const SizedBox(width: 8),
                          Text(
                            'Filter Members',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: textPrimary,
                            ),
                          ),
                          if (tempActiveCount > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: primaryColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$tempActiveCount active',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Row(
                        children: [
                          if (tempActiveCount > 0)
                            TextButton(
                              onPressed: () {
                                setModalState(() {
                                  tempType = 'All';
                                  tempCompleteness = 'All';
                                  tempStatus = 'All';
                                  tempCategory = 'All';
                                });
                              },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                visualDensity: VisualDensity.compact,
                              ),
                              child: Text(
                                'Reset All',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: primaryColor,
                                ),
                              ),
                            ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 22),
                            color: textSecondary,
                            onPressed: () => Navigator.of(modalCtx).pop(),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Divider(color: borderColor, height: 1),
                  const SizedBox(height: 14),

                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Membership Type (Old, New)
                          _buildModalSectionHeader('MEMBERSHIP TYPE', textSecondary),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildModalChoiceChip(
                                label: 'All Types',
                                count: centerMembers.length,
                                isSelected: tempType == 'All',
                                onTap: () => setModalState(() => tempType = 'All'),
                                primaryColor: primaryColor,
                                isDark: isDark,
                              ),
                              _buildModalChoiceChip(
                                label: 'Old',
                                count: oldCount,
                                isSelected: tempType == 'Old',
                                onTap: () => setModalState(() => tempType = tempType == 'Old' ? 'All' : 'Old'),
                                primaryColor: primaryColor,
                                accentColor: const Color(0xFF00B0FF),
                                isDark: isDark,
                              ),
                              _buildModalChoiceChip(
                                label: 'New',
                                count: newCount,
                                isSelected: tempType == 'New',
                                onTap: () => setModalState(() => tempType = tempType == 'New' ? 'All' : 'New'),
                                primaryColor: primaryColor,
                                accentColor: const Color(0xFF2979FF),
                                isDark: isDark,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // 2. Profile Completeness (Complete, Incomplete)
                          _buildModalSectionHeader('PROFILE COMPLETENESS', textSecondary),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildModalChoiceChip(
                                label: 'All',
                                count: centerMembers.length,
                                isSelected: tempCompleteness == 'All',
                                onTap: () => setModalState(() => tempCompleteness = 'All'),
                                primaryColor: primaryColor,
                                isDark: isDark,
                              ),
                              _buildModalChoiceChip(
                                label: 'Complete',
                                count: completeCount,
                                isSelected: tempCompleteness == 'Complete',
                                onTap: () => setModalState(() => tempCompleteness = tempCompleteness == 'Complete' ? 'All' : 'Complete'),
                                primaryColor: primaryColor,
                                accentColor: const Color(0xFF00C853),
                                isDark: isDark,
                              ),
                              _buildModalChoiceChip(
                                label: 'Incomplete',
                                count: incompleteCount,
                                isSelected: tempCompleteness == 'Incomplete',
                                onTap: () => setModalState(() => tempCompleteness = tempCompleteness == 'Incomplete' ? 'All' : 'Incomplete'),
                                primaryColor: primaryColor,
                                accentColor: Colors.amber.shade800,
                                isDark: isDark,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // 3. Status (Active, Inactive)
                          _buildModalSectionHeader('MEMBERSHIP STATUS', textSecondary),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildModalChoiceChip(
                                label: 'All',
                                count: centerMembers.length,
                                isSelected: tempStatus == 'All',
                                onTap: () => setModalState(() => tempStatus = 'All'),
                                primaryColor: primaryColor,
                                isDark: isDark,
                              ),
                              _buildModalChoiceChip(
                                label: 'Active',
                                count: activeCount,
                                isSelected: tempStatus == 'Active',
                                onTap: () => setModalState(() => tempStatus = tempStatus == 'Active' ? 'All' : 'Active'),
                                primaryColor: primaryColor,
                                accentColor: primaryColor,
                                isDark: isDark,
                              ),
                              _buildModalChoiceChip(
                                label: 'Inactive',
                                count: inactiveCount,
                                isSelected: tempStatus == 'Inactive',
                                onTap: () => setModalState(() => tempStatus = tempStatus == 'Inactive' ? 'All' : 'Inactive'),
                                primaryColor: primaryColor,
                                accentColor: Colors.redAccent,
                                isDark: isDark,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // 4. Ministry Category (Adult, FYS, Kiddies)
                          _buildModalSectionHeader('MINISTRY CATEGORY', textSecondary),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildModalChoiceChip(
                                label: 'All Categories',
                                count: centerMembers.length,
                                isSelected: tempCategory == 'All',
                                onTap: () => setModalState(() => tempCategory = 'All'),
                                primaryColor: primaryColor,
                                isDark: isDark,
                              ),
                              _buildModalChoiceChip(
                                label: 'Adult',
                                count: adultCount,
                                isSelected: tempCategory == 'Adult',
                                onTap: () => setModalState(() => tempCategory = tempCategory == 'Adult' ? 'All' : 'Adult'),
                                primaryColor: primaryColor,
                                accentColor: const Color(0xFF00B0FF),
                                isDark: isDark,
                              ),
                              _buildModalChoiceChip(
                                label: 'FYS',
                                count: fysCount,
                                isSelected: tempCategory == 'FYS',
                                onTap: () => setModalState(() => tempCategory = tempCategory == 'FYS' ? 'All' : 'FYS'),
                                primaryColor: primaryColor,
                                accentColor: const Color(0xFFA100FF),
                                isDark: isDark,
                              ),
                              _buildModalChoiceChip(
                                label: 'Kiddies',
                                count: kiddiesCount,
                                isSelected: tempCategory == 'Kiddies',
                                onTap: () => setModalState(() => tempCategory = tempCategory == 'Kiddies' ? 'All' : 'Kiddies'),
                                primaryColor: primaryColor,
                                accentColor: const Color(0xFFFF9100),
                                isDark: isDark,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Divider(color: borderColor, height: 1),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _selectedType = tempType;
                          _selectedCompleteness = tempCompleteness;
                          _selectedStatus = tempStatus;
                          _selectedCategory = tempCategory;
                        });
                        Navigator.of(modalCtx).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Apply Filters',
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
      ),
    );
  }

  Widget _buildStatColumn({
    required BuildContext context,
    required String label,
    required int count,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? const Color(0xFFF5F5FA) : const Color(0xFF0E0E14);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 0.8,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 3),
        Text(
          _countFormat.format(count),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: textPrimary,
          ),
        ),
      ],
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
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF16161F) : Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.center.centerName,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${widget.center.district} • ${widget.center.area}',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: textSecondary,
              ),
            ),
          ],
        ),
      ),
      body: StreamBuilder<List<Member>>(
        stream: _firestoreService.getMembersStream(),
        builder: (context, snapshot) {
          final allMembers = snapshot.data ?? [];
          final allCenters = _allCenters.isNotEmpty
              ? _allCenters
              : [widget.center];

          // 1. All members belonging to this specific local center
          final centerMembers = allMembers
              .where((m) => _memberBelongsToCenter(m, widget.center, allCenters))
              .toList()
            ..sort((a, b) {
              if (a.isInactive != b.isInactive) {
                return a.isInactive ? 1 : -1; // Active members first, inactive members below
              }
              return a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase());
            });

          // 2. Center-specific metrics
          final activeMembers = centerMembers.where((m) => !m.isInactive).toList();
          final activeCount = activeMembers.length;
          final inactiveCount =
              centerMembers.where((m) => m.isInactive).length;

          final completeActiveCount =
              activeMembers.where((m) => m.isProfileComplete).length;
          final incompleteActiveCount =
              activeMembers.where((m) => !m.isProfileComplete).length;

          final double completenessRate = activeCount > 0
              ? (completeActiveCount / activeCount)
              : 0.0;

          // 3. Financial calculations
          double centerMemberDues = 0.0;
          for (final m in activeMembers) {
            centerMemberDues += m.assessmentRate;
          }
          final double centerObligation = CenterModel.totalCenterObligation;
          final double centerTotalAssessed = centerMemberDues + centerObligation;

          // 4. Filtered members for roster list based on all filter dimensions & search
          final filteredMembers = centerMembers.where((m) {
            // Type filter: Old / New
            if (_selectedType == 'Old' && m.memberType.trim().toLowerCase() != 'old') {
              return false;
            }
            if (_selectedType == 'New' && m.memberType.trim().toLowerCase() != 'new') {
              return false;
            }

            // Completeness filter: Complete / Incomplete
            if (_selectedCompleteness == 'Complete' && !m.isProfileComplete) {
              return false;
            }
            if (_selectedCompleteness == 'Incomplete' && m.isProfileComplete) {
              return false;
            }

            // Status filter: Active / Inactive
            if (_selectedStatus == 'Active' && m.isInactive) {
              return false;
            }
            if (_selectedStatus == 'Inactive' && !m.isInactive) {
              return false;
            }

            // Ministry Category filter: Adult / FYS / Kiddies
            if (_selectedCategory != 'All') {
              final cat = m.dynamicCategory.trim().toLowerCase();
              final rawCat = m.category.trim().toLowerCase();
              final target = _selectedCategory.trim().toLowerCase();
              if (cat != target && rawCat != target) {
                return false;
              }
            }

            // Search query
            if (_searchQuery.isNotEmpty) {
              final q = _searchQuery.toLowerCase();
              final matches = m.fullName.toLowerCase().contains(q) ||
                  m.memberId.toLowerCase().contains(q) ||
                  m.primaryPosition.toLowerCase().contains(q) ||
                  m.contactNo.toLowerCase().contains(q);
              if (!matches) return false;
            }

            return true;
          }).toList()
            ..sort((a, b) {
              if (a.isInactive != b.isInactive) {
                return a.isInactive ? 1 : -1; // Active members first, inactive members below
              }
              return a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase());
            });

          return CustomScrollView(
            slivers: [
              // Header Card Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // CENTER OVERVIEW HERO CARD
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
                            // Header Row: Center Name & Completeness Circular Ring
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
                                        'LOCAL CHURCH CENTER STATUS',
                                        style: TextStyle(
                                          color: primaryColor,
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        widget.center.centerName,
                                        style: TextStyle(
                                          color: textPrimary,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.location_on_outlined,
                                            size: 14,
                                            color: textSecondary,
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              widget.center.centerAddress.trim().isNotEmpty
                                                  ? widget.center.centerAddress.trim()
                                                  : '${widget.center.district} • ${widget.center.area}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: textSecondary,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 14),

                                // Completeness Circular Progress
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    SizedBox(
                                      width: 58,
                                      height: 58,
                                      child: CircularProgressIndicator(
                                        value: completenessRate,
                                        strokeWidth: 5.5,
                                        strokeCap: StrokeCap.round,
                                        backgroundColor: isDark
                                            ? Colors.white.withValues(alpha: 0.08)
                                            : Colors.black.withValues(alpha: 0.06),
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          completenessRate >= 0.8
                                              ? const Color(0xFF00C853)
                                              : (completenessRate >= 0.5
                                                  ? Colors.amber.shade800
                                                  : Colors.orange),
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${(completenessRate * 100).toStringAsFixed(0)}%',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Divider(color: borderColor, height: 1),
                            const SizedBox(height: 14),

                            // Metric Breakdown: Complete, Incomplete, Active, Inactive
                            Row(
                              children: [
                                Expanded(
                                  child: _buildStatColumn(
                                    context: context,
                                    label: 'Complete',
                                    count: completeActiveCount,
                                    color: const Color(0xFF00C853),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: _buildStatColumn(
                                    context: context,
                                    label: 'Incomplete',
                                    count: incompleteActiveCount,
                                    color: Colors.amber.shade800,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: _buildStatColumn(
                                    context: context,
                                    label: 'Active',
                                    count: activeCount,
                                    color: primaryColor,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: _buildStatColumn(
                                    context: context,
                                    label: 'Inactive',
                                    count: inactiveCount,
                                    color: Colors.redAccent,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Divider(color: borderColor, height: 1),
                            const SizedBox(height: 12),

                            // Financial Obligations Summary
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'TOTAL FINANCIAL ASSESSMENT',
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w700,
                                        color: textSecondary,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '₱${_wholeCurrencyFormat.format(centerMemberDues)} member dues + ₱${_wholeCurrencyFormat.format(centerObligation)} obligations',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  '₱${_wholeCurrencyFormat.format(centerTotalAssessed)}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF00C853),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Section Title & Search for Member Roster
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'CENTER MEMBERS ROSTER',
                            style: TextStyle(
                              color: primaryColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                          ),
                          Text(
                            '${filteredMembers.length} Members',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Search Field & Filter Button
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: cardBg,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: borderColor, width: 1.1),
                              ),
                              child: TextField(
                                controller: _searchController,
                                onChanged: (val) {
                                  setState(() {
                                    _searchQuery = val.trim();
                                  });
                                },
                                decoration: InputDecoration(
                                  hintText: 'Search members by name, ID, or position...',
                                  hintStyle: TextStyle(
                                    color: textSecondary.withValues(alpha: 0.7),
                                    fontSize: 13.5,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.search_rounded,
                                    color: textSecondary,
                                    size: 20,
                                  ),
                                  suffixIcon: _searchQuery.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear, size: 18),
                                          onPressed: () {
                                            _searchController.clear();
                                            setState(() {
                                              _searchQuery = '';
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

                          // Filter Button with Active Badge
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _openFilterBottomSheet(context, centerMembers),
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: _hasActiveFilter
                                      ? primaryColor.withValues(alpha: isDark ? 0.25 : 0.12)
                                      : cardBg,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: _hasActiveFilter ? primaryColor : borderColor,
                                    width: _hasActiveFilter ? 1.5 : 1.1,
                                  ),
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Icon(
                                      Icons.tune_rounded,
                                      size: 22,
                                      color: _hasActiveFilter ? primaryColor : textPrimary,
                                    ),
                                    if (_hasActiveFilter)
                                      Positioned(
                                        top: 6,
                                        right: 6,
                                        child: Container(
                                          width: 16,
                                          height: 16,
                                          decoration: BoxDecoration(
                                            color: primaryColor,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Text(
                                              '$_activeFilterCount',
                                              style: const TextStyle(
                                                fontSize: 9.5,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Member List
              if (filteredMembers.isEmpty)
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
                            Icons.people_outline_rounded,
                            size: 44,
                            color: textSecondary.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'No members match "$_searchQuery"'
                                : 'No members in this category',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Try selecting another filter or searching a different name.',
                            style: TextStyle(
                              fontSize: 13,
                              color: textSecondary,
                            ),
                          ),
                          if (_hasActiveFilter) ...[
                            const SizedBox(height: 14),
                            OutlinedButton.icon(
                              onPressed: _resetAllFilters,
                              icon: const Icon(Icons.clear_all_rounded, size: 16),
                              label: const Text('Reset All Filters'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: primaryColor,
                                side: BorderSide(color: primaryColor.withValues(alpha: 0.5)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final member = filteredMembers[index];
                      final isComplete = member.isProfileComplete;
                      final missing = member.missingFields;

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
                                  builder: (context) => MemberDetailsScreen(
                                    member: member,
                                    allMembers: allMembers,
                                  ),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      // Member Avatar
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: SizedBox(
                                          width: 46,
                                          height: 46,
                                          child: member.profileUrl.isNotEmpty &&
                                                  member.profileUrl != 'N/A'
                                              ? CachedNetworkImage(
                                                  imageUrl: member.profileUrl,
                                                  fit: BoxFit.cover,
                                                  placeholder: (ctx, url) =>
                                                      Container(
                                                    color: primaryColor.withValues(
                                                      alpha: isDark ? 0.2 : 0.1,
                                                    ),
                                                  ),
                                                  errorWidget:
                                                      (ctx, url, error) =>
                                                          _buildAvatarFallback(
                                                    member,
                                                    primaryColor,
                                                    isDark,
                                                  ),
                                                )
                                              : _buildAvatarFallback(
                                                  member,
                                                  primaryColor,
                                                  isDark,
                                                ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),

                                      // Member Name & Info
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              member.fullName,
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                color: textPrimary,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              '${member.memberId} • ${member.primaryPosition.isNotEmpty ? member.primaryPosition : member.dynamicCategory}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: textSecondary,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 5.5,
                                                    vertical: 1.5,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: (member.memberType.toLowerCase() == 'new'
                                                            ? const Color(0xFF2979FF)
                                                            : const Color(0xFF00B0FF))
                                                        .withValues(alpha: isDark ? 0.22 : 0.12),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    member.memberType.toUpperCase(),
                                                    style: TextStyle(
                                                      fontSize: 9.5,
                                                      fontWeight: FontWeight.w800,
                                                      letterSpacing: 0.4,
                                                      color: member.memberType.toLowerCase() == 'new'
                                                          ? const Color(0xFF2979FF)
                                                          : const Color(0xFF00B0FF),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 5),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 5.5,
                                                    vertical: 1.5,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: isDark
                                                        ? Colors.white10
                                                        : Colors.black.withValues(alpha: 0.05),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    member.dynamicCategory,
                                                    style: TextStyle(
                                                      fontSize: 9.5,
                                                      fontWeight: FontWeight.w700,
                                                      color: textSecondary,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),

                                      // Status Badge
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3.5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: member.isInactive
                                              ? Colors.redAccent.withValues(
                                                  alpha: isDark ? 0.2 : 0.1,
                                                )
                                              : (isComplete
                                                  ? const Color(0xFF00C853)
                                                      .withValues(
                                                      alpha: isDark ? 0.2 : 0.1,
                                                    )
                                                  : Colors.amber.shade800
                                                      .withValues(
                                                      alpha: isDark ? 0.2 : 0.1,
                                                    )),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          member.isInactive
                                              ? 'Inactive'
                                              : (isComplete
                                                  ? 'Complete'
                                                  : 'Incomplete'),
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w700,
                                            color: member.isInactive
                                                ? Colors.redAccent
                                                : (isComplete
                                                    ? const Color(0xFF00C853)
                                                    : Colors.amber.shade800),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  // Missing Fields Checklist Tags for Incomplete Profiles
                                  if (!isComplete && missing.isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 4,
                                      children: [
                                        ...missing.take(3).map((f) => Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.amber.shade800
                                                    .withValues(
                                                  alpha: isDark ? 0.15 : 0.08,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                                border: Border.all(
                                                  color: Colors.amber.shade800
                                                      .withValues(alpha: 0.3),
                                                  width: 0.8,
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.close_rounded,
                                                    size: 10,
                                                    color: Colors.amber.shade800,
                                                  ),
                                                  const SizedBox(width: 3),
                                                  Text(
                                                    f,
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.w600,
                                                      color: Colors.amber.shade800,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            )),
                                        if (missing.length > 3)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isDark
                                                  ? Colors.white10
                                                  : Colors.black.withValues(
                                                      alpha: 0.05,
                                                    ),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              '+${missing.length - 3} more',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                                color: textSecondary,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }, childCount: filteredMembers.length),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAvatarFallback(Member member, Color primaryColor, bool isDark) {
    return Container(
      color: primaryColor.withValues(alpha: isDark ? 0.22 : 0.12),
      alignment: Alignment.center,
      child: Text(
        member.initials,
        style: TextStyle(
          color: primaryColor,
          fontWeight: FontWeight.w800,
          fontSize: 16,
        ),
      ),
    );
  }
}
