import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/center_model.dart';
import '../models/member.dart';
import '../services/database_service.dart';
import '../services/firestore_service.dart';
import '../widgets/stats_filter_bottom_sheet.dart';
import 'center_details_screen.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final DatabaseService _databaseService = DatabaseService();
  final NumberFormat _countFormat = NumberFormat('#,##0', 'en_US');

  final TextEditingController _searchController = TextEditingController();
  String _centerSearchQuery = '';
  List<CenterModel> _databaseCenters = [];
  bool _isLoadingCenters = true;
  Member? _currentMember;

  StatsFilterCriteria _filterCriteria = const StatsFilterCriteria();

  @override
  void initState() {
    super.initState();
    _loadCenters();
    _firestoreService.getCurrentMember().then((user) {
      if (mounted && user != null) {
        setState(() {
          _currentMember = user;
          String dist = _filterCriteria.district;
          String ar = _filterCriteria.area;
          String cen = _filterCriteria.center;
          if (user.isDistrictLocked && user.district.isNotEmpty) {
            dist = user.district;
          }
          if (user.isAreaLocked && user.area.isNotEmpty) {
            ar = user.area;
          }
          if (user.isCenterLocked && user.center.isNotEmpty) {
            cen = user.center;
          }
          _filterCriteria = _filterCriteria.copyWith(
            district: dist,
            area: ar,
            center: cen,
          );
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

  void _openFilterBottomSheet(List<CenterModel> allCenters) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatsFilterBottomSheet(
        currentFilter: _filterCriteria,
        allCenters: allCenters,
        currentMember: _currentMember,
        onApply: (newCriteria) {
          setState(() {
            _filterCriteria = newCriteria;
          });
        },
      ),
    );
  }

  Map<String, dynamic> _getCenterStats(
    CenterModel center,
    List<Member> allMembers,
    List<CenterModel> allCenters,
  ) {
    final cMembers = allMembers.where((m) {
      final mCenter = m.center.trim().toLowerCase();
      final cName = center.centerName.trim().toLowerCase();
      final cDisplay = center.displayNameWithAddress.trim().toLowerCase();
      final cAddr = center.centerAddress.trim().toLowerCase();

      if (mCenter.isEmpty) return false;

      // 1. Exact match with display name including address
      if (mCenter == cDisplay) return true;

      // 2. Exact match with center name
      if (mCenter == cName) {
        // Check if other centers share this exact same name
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
          // Disambiguate by area if available
          if (m.area.trim().isNotEmpty && center.area.trim().isNotEmpty) {
            if (m.area.trim().toLowerCase() ==
                center.area.trim().toLowerCase()) {
              return true;
            }
          }
          // Disambiguate by location in center address
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
          // Disambiguate by district
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
    }).toList();

    final cActiveMembers = cMembers.where((m) => !m.isInactive).toList();
    final cActiveCount = cActiveMembers.length;
    final cCompleteCount = cActiveMembers
        .where((m) => m.isProfileComplete)
        .length;
    final double centerRatio = cActiveCount > 0
        ? (cCompleteCount / cActiveCount)
        : 0.0;
    final int percentage = (centerRatio * 100).round();

    return {
      'members': cMembers,
      'activeMembers': cActiveMembers,
      'activeCount': cActiveCount,
      'completeCount': cCompleteCount,
      'ratio': centerRatio,
      'percentage': percentage,
    };
  }

  Widget _buildStatMetric({
    required BuildContext context,
    required String label,
    required int count,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark
        ? const Color(0xFFF5F5FA)
        : const Color(0xFF0E0E14);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: color,
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
    final textPrimary = isDark
        ? const Color(0xFFF5F5FA)
        : const Color(0xFF0E0E14);
    final textSecondary = isDark
        ? const Color(0xFF9E9EAF)
        : const Color(0xFF6E6E82);
    final cardBg = isDark ? const Color(0xFF16161F) : Colors.white;
    final borderColor = isDark
        ? const Color(0xFF262633)
        : const Color(0xFFE5E5ED);

    return Scaffold(
      body: StreamBuilder<List<Member>>(
        stream: _firestoreService.getMembersStream(),
        builder: (context, snapshot) {
          final allMembers = snapshot.data ?? [];

          // 1. Centers list strictly relies on the predefined SQLite database
          final allCenters = List<CenterModel>.from(_databaseCenters);

          // 2. Scope predefined centers by active jurisdiction filter
          final scopedCenters = allCenters.where((c) {
            final matchDistrict =
                _filterCriteria.district == 'All Districts' ||
                c.district.toLowerCase() ==
                    _filterCriteria.district.toLowerCase();
            final matchArea =
                _filterCriteria.area == 'All Areas' ||
                c.area.toLowerCase() == _filterCriteria.area.toLowerCase();
            final matchCenter =
                _filterCriteria.center == 'All Local Centers' ||
                c.centerName.toLowerCase() ==
                    _filterCriteria.center.toLowerCase() ||
                c.displayNameWithAddress.toLowerCase() ==
                    _filterCriteria.center.toLowerCase();
            return matchDistrict && matchArea && matchCenter;
          }).toList();

          // 3. Scope members by active jurisdiction filter
          final scopedMembers = allMembers.where((m) {
            final matchDistrict =
                _filterCriteria.district == 'All Districts' ||
                m.district.toLowerCase() ==
                    _filterCriteria.district.toLowerCase();
            final matchArea =
                _filterCriteria.area == 'All Areas' ||
                m.area.toLowerCase() == _filterCriteria.area.toLowerCase();
            final matchCenter =
                _filterCriteria.center == 'All Local Centers' ||
                m.center.toLowerCase() ==
                    _filterCriteria.center.toLowerCase() ||
                _filterCriteria.center.toLowerCase().contains(
                  m.center.toLowerCase(),
                );

            return matchDistrict && matchArea && matchCenter;
          }).toList();

          // 4. Compute Global Membership & Completeness Statistics based on scoped data
          final totalMembersCount = scopedMembers.length;

          // Active members only for profile completeness rate
          final activeMembers = scopedMembers
              .where((m) => !m.isInactive)
              .toList();
          final activeCount = activeMembers.length;
          final inactiveCount = scopedMembers.where((m) => m.isInactive).length;

          final completeActiveCount = activeMembers
              .where((m) => m.isProfileComplete)
              .length;
          final incompleteActiveCount = activeMembers
              .where((m) => !m.isProfileComplete)
              .length;

          // Profile completeness rate strictly counts active members (excluding inactive members)
          final double completenessRate = activeCount > 0
              ? (completeActiveCount / activeCount)
              : 0.0;

          // 5. Filter centers for the list based on search query AND completeness percentage filter
          final filteredCenters =
              scopedCenters.where((center) {
                // Search query filter
                if (_centerSearchQuery.isNotEmpty) {
                  final q = _centerSearchQuery.toLowerCase();
                  final matchesSearch =
                      center.centerName.toLowerCase().contains(q) ||
                      center.centerAddress.toLowerCase().contains(q) ||
                      center.area.toLowerCase().contains(q) ||
                      center.district.toLowerCase().contains(q);
                  if (!matchesSearch) return false;
                }

                // Completeness percentage filter (0%, 10%...100%)
                if (_filterCriteria.completenessPercentage != 'All') {
                  final targetPct =
                      int.tryParse(
                        _filterCriteria.completenessPercentage.replaceAll(
                          '%',
                          '',
                        ),
                      ) ??
                      0;
                  final stats = _getCenterStats(center, allMembers, allCenters);
                  final int pct = stats['percentage'] as int;

                  if (_filterCriteria.atLeastPercentage) {
                    if (targetPct == 0) {
                      // Specifically 0% completeness
                      if (pct != 0) return false;
                    } else {
                      if (pct < targetPct) return false;
                    }
                  } else {
                    // Exact tier
                    if (targetPct == 100) {
                      if (pct < 100) return false;
                    } else if (targetPct == 0) {
                      if (pct > 9) return false;
                    } else {
                      if (pct < targetPct || pct >= targetPct + 10) {
                        return false;
                      }
                    }
                  }
                }

                return true;
              }).toList()..sort((a, b) {
                final nameComp = a.centerName.toLowerCase().compareTo(
                  b.centerName.toLowerCase(),
                );
                if (nameComp != 0) return nameComp;
                return a.centerAddress.toLowerCase().compareTo(
                  b.centerAddress.toLowerCase(),
                );
              });

          return CustomScrollView(
            slivers: [
              // Header Section & Analytics Card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // DISTRICT MEMBERSHIP STATS Hero Card
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
                            // Header Top: Stats Overview & Circular Completeness Progress
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Header label: DISTRICT MEMBERSHIP STATS
                                      Text(
                                        _filterCriteria.district !=
                                                'All Districts'
                                            ? '${_filterCriteria.district} MEMBERSHIP STATS'
                                                .toUpperCase()
                                            : 'DISTRICT MEMBERSHIP STATS',
                                        style: TextStyle(
                                          color: primaryColor,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '${_countFormat.format(totalMembersCount)} Members',
                                        style: TextStyle(
                                          color: textPrimary,
                                          fontSize: 22,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Profile Completeness Rate',
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600,
                                          color: textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Circular Progress Indicator with Percentage
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    SizedBox(
                                      width: 56,
                                      height: 56,
                                      child: CircularProgressIndicator(
                                        value: completenessRate,
                                        strokeWidth: 5,
                                        strokeCap: StrokeCap.round,
                                        backgroundColor: isDark
                                            ? Colors.white.withValues(
                                                alpha: 0.08,
                                              )
                                            : Colors.black.withValues(
                                                alpha: 0.06,
                                              ),
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
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
                                        fontSize: 13.5,
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

                            // 4 Metric Breakdown: Complete, Incomplete, Active, Inactive
                            Row(
                              children: [
                                Expanded(
                                  child: _buildStatMetric(
                                    context: context,
                                    label: 'Complete',
                                    count: completeActiveCount,
                                    color: const Color(0xFF00C853),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildStatMetric(
                                    context: context,
                                    label: 'Incomplete',
                                    count: incompleteActiveCount,
                                    color: Colors.amber.shade800,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildStatMetric(
                                    context: context,
                                    label: 'Active',
                                    count: activeCount,
                                    color: primaryColor,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildStatMetric(
                                    context: context,
                                    label: 'Inactive',
                                    count: inactiveCount,
                                    color: Colors.redAccent,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Section Title & Search for Centers List
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'LOCAL CHURCH CENTERS',
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
                                '${filteredCenters.length} Listed',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: textSecondary,
                                ),
                              ),
                              if (_filterCriteria.hasActiveFilter) ...[
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _filterCriteria =
                                          const StatsFilterCriteria();
                                    });
                                  },
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

                      // Search centers filter input and Filter Button row matching Member Directory
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              onChanged: (val) {
                                setState(() {
                                  _centerSearchQuery = val.trim();
                                });
                              },
                              decoration: InputDecoration(
                                hintText: 'Search center name or address...',
                                prefixIcon: const Icon(
                                  Icons.search_rounded,
                                  size: 20,
                                ),
                                suffixIcon: _centerSearchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(
                                          Icons.clear_rounded,
                                          size: 18,
                                        ),
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() {
                                            _centerSearchQuery = '';
                                          });
                                        },
                                      )
                                    : null,
                                filled: true,
                                fillColor: cardBg,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: borderColor),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: borderColor),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(
                                    color: primaryColor,
                                    width: 1.8,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),

                          // Filter Button
                          InkWell(
                            onTap: () => _openFilterBottomSheet(allCenters),
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: _filterCriteria.hasActiveFilter
                                    ? primaryColor.withValues(alpha: 0.15)
                                    : cardBg,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: _filterCriteria.hasActiveFilter
                                      ? primaryColor
                                      : borderColor,
                                  width: _filterCriteria.hasActiveFilter
                                      ? 1.5
                                      : 1.1,
                                ),
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Icon(
                                    Icons.tune_rounded,
                                    size: 22,
                                    color: _filterCriteria.hasActiveFilter
                                        ? primaryColor
                                        : textPrimary,
                                  ),
                                  if (_filterCriteria.hasActiveFilter)
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
                                            '${_filterCriteria.activeFilterCount}',
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
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Centers List Loading State
              if ((snapshot.connectionState == ConnectionState.waiting &&
                      allMembers.isEmpty) ||
                  _isLoadingCenters)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(40.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                )
              // Empty Centers State
              else if (filteredCenters.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.church_outlined,
                            size: 52,
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
                            'Try searching with a different term.',
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
              // Centers List
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final center = filteredCenters[index];

                      // Calculate center-specific completeness using unified helper
                      final stats = _getCenterStats(
                        center,
                        allMembers,
                        allCenters,
                      );
                      final cMembers = stats['members'] as List<Member>;
                      final cActiveCount = stats['activeCount'] as int;
                      final double centerRatio = stats['ratio'] as double;

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
                                  // Center Info: Center Name and below it the Center Address
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
                                                    : 'Local Center Address on file'),
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
                                          '${center.area.isNotEmpty ? "${center.area} • " : ""}${cMembers.length} ${cMembers.length == 1 ? "member" : "members"} ($cActiveCount active)',
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

                                  // Trailing: Circular Progress Indicator with Completeness Percentage inside
                                  Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      SizedBox(
                                        width: 44,
                                        height: 44,
                                        child: CircularProgressIndicator(
                                          value: centerRatio,
                                          strokeWidth: 4,
                                          backgroundColor: isDark
                                              ? Colors.white.withValues(
                                                  alpha: 0.08,
                                                )
                                              : Colors.black.withValues(
                                                  alpha: 0.06,
                                                ),
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            centerRatio >= 0.8
                                                ? const Color(0xFF00C853)
                                                : (centerRatio >= 0.5
                                                      ? Colors.amber.shade800
                                                      : Colors.orange),
                                          ),
                                        ),
                                      ),
                                      Text(
                                        '${(centerRatio * 100).toStringAsFixed(0)}%',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w800,
                                          color: textPrimary,
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
