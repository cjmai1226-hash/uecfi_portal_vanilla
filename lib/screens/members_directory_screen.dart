import 'package:flutter/material.dart';
import '../models/center_model.dart';
import '../models/member.dart';
import '../services/database_service.dart';
import '../services/firestore_service.dart';
import '../widgets/member_filter_bottom_sheet.dart';
import 'member_details_screen.dart';

class MembersDirectoryScreen extends StatefulWidget {
  const MembersDirectoryScreen({super.key});

  @override
  State<MembersDirectoryScreen> createState() => _MembersDirectoryScreenState();
}

class _MembersDirectoryScreenState extends State<MembersDirectoryScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final DatabaseService _databaseService = DatabaseService();
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  MemberFilterCriteria _filterCriteria = const MemberFilterCriteria();
  List<CenterModel> _allCenters = [];
  Member? _currentMember;

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

  Future<void> _loadCenters() async {
    final centers = await _databaseService.getCenters();
    if (mounted) {
      setState(() {
        _allCenters = centers;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => MemberFilterBottomSheet(
        currentFilter: _filterCriteria,
        allCenters: _allCenters,
        currentMember: _currentMember,
        onApply: (newCriteria) {
          setState(() {
            _filterCriteria = newCriteria;
          });
        },
      ),
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

          // Populate centers fallback dynamically if database returned empty
          if (_allCenters.isEmpty && allMembers.isNotEmpty) {
            final dynamicCenters = allMembers
                .map((m) => CenterModel(
                      id: 0,
                      centerName: m.center,
                      district: m.district,
                      area: m.area,
                    ))
                .where((c) => c.centerName.trim().isNotEmpty)
                .toList();
            _allCenters = dynamicCenters;
          }

          // Build duplicate name map for instant O(1) duplicate lookup
          final Map<String, List<Member>> nameToMembers = {};
          for (final m in allMembers) {
            final key = m.duplicateNameKey;
            if (m.firstName.trim().isNotEmpty && m.lastName.trim().isNotEmpty) {
              nameToMembers.putIfAbsent(key, () => []).add(m);
            }
          }

          // Apply full filter criteria
          final filteredMembers = allMembers.where((m) {
            // 1. Search query filter
            if (_searchQuery.isNotEmpty) {
              final q = _searchQuery.toLowerCase();
              final matchesQuery = m.fullName.toLowerCase().contains(q) ||
                  m.memberId.toLowerCase().contains(q) ||
                  m.positionsSummary.toLowerCase().contains(q) ||
                  m.center.toLowerCase().contains(q);
              if (!matchesQuery) return false;
            }

            // 2. District filter
            if (_filterCriteria.district != 'All Districts' &&
                m.district.trim().toLowerCase() != _filterCriteria.district.trim().toLowerCase()) {
              return false;
            }

            // 3. Area filter
            if (_filterCriteria.area != 'All Areas' &&
                m.area.trim().toLowerCase() != _filterCriteria.area.trim().toLowerCase()) {
              return false;
            }

            // 4. Center filter
            if (_filterCriteria.center != 'All Local Centers' &&
                m.center.trim().toLowerCase() != _filterCriteria.center.trim().toLowerCase()) {
              return false;
            }

            // 5. Status filter (Active / Inactive)
            if (_filterCriteria.status == 'Active' && m.isInactive) {
              return false;
            }
            if (_filterCriteria.status == 'Inactive' && !m.isInactive) {
              return false;
            }

            // 6. Completeness filter (Complete / Incomplete)
            if (_filterCriteria.completeness == 'Complete' && !m.isProfileComplete) {
              return false;
            }
            if (_filterCriteria.completeness == 'Incomplete' && m.isProfileComplete) {
              return false;
            }

            // 7. Duplicates Only filter
            if (_filterCriteria.duplicatesOnly) {
              final sameNameMembers = nameToMembers[m.duplicateNameKey] ?? [];
              final hasDuplicate = sameNameMembers.any((other) =>
                  other.memberId != m.memberId &&
                  (other.id.isEmpty || m.id.isEmpty || other.id != m.id));
              if (!hasDuplicate) return false;
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
              // Header & Search + Filter Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: borderColor, width: 1.2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'REGISTRY & RECORDS',
                                  style: TextStyle(
                                    color: primaryColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.6,
                                  ),
                                ),
                                if (snapshot.hasData)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: primaryColor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${filteredMembers.length} Members',
                                      style: TextStyle(
                                        color: primaryColor,
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Members Directory',
                              style: TextStyle(
                                color: textPrimary,
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Directory listings, local church center memberships, and profile registry.',
                              style: TextStyle(
                                color: textSecondary,
                                fontSize: 14,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Search input and Filter Icon row
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              onChanged: (val) {
                                setState(() {
                                  _searchQuery = val.trim();
                                });
                              },
                              decoration: InputDecoration(
                                hintText: 'Search members...',
                                prefixIcon: const Icon(Icons.search_rounded, size: 22),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear_rounded, size: 20),
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() {
                                            _searchQuery = '';
                                          });
                                        },
                                      )
                                    : null,
                                filled: true,
                                fillColor: cardBg,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                                  borderSide: BorderSide(color: primaryColor, width: 1.8),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),

                          // Filter Button
                          InkWell(
                            onTap: _openFilterBottomSheet,
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: _filterCriteria.hasActiveFilter
                                    ? primaryColor.withValues(alpha: 0.15)
                                    : cardBg,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: _filterCriteria.hasActiveFilter ? primaryColor : borderColor,
                                  width: _filterCriteria.hasActiveFilter ? 1.5 : 1.1,
                                ),
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Icon(
                                    Icons.tune_rounded,
                                    size: 24,
                                    color: _filterCriteria.hasActiveFilter ? primaryColor : textPrimary,
                                  ),
                                  if (_filterCriteria.hasActiveFilter)
                                    Positioned(
                                      top: 8,
                                      right: 8,
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

              // Loading State
              if (snapshot.connectionState == ConnectionState.waiting)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(40.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                )
              // Error State
              else if (snapshot.hasError)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Text(
                        'Failed to load members: ${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: textSecondary),
                      ),
                    ),
                  ),
                )
              // Empty State
              else if (filteredMembers.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.people_outline_rounded,
                            size: 56,
                            color: textSecondary.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _searchQuery.isNotEmpty || _filterCriteria.hasActiveFilter
                                ? 'No matching members found'
                                : 'No members registered yet',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _searchQuery.isNotEmpty || _filterCriteria.hasActiveFilter
                                ? 'Try adjusting your search query or reset filter settings.'
                                : 'District 3 members will appear here once registered.',
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
              // Members List
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final member = filteredMembers[index];
                        final isInactive = member.isInactive;
                        final isComplete = member.isProfileComplete;

                        final matchingMembers = nameToMembers[member.duplicateNameKey] ?? [];
                        final duplicatesInOtherCenters = matchingMembers.where((other) {
                          if (other.memberId == member.memberId) return false;
                          if (other.id.isNotEmpty && member.id.isNotEmpty && other.id == member.id) return false;
                          return other.center.trim().toLowerCase() != member.center.trim().toLowerCase();
                        }).toList();

                        final otherCenters = duplicatesInOtherCenters
                            .map((d) => d.center.trim())
                            .where((c) => c.isNotEmpty)
                            .toSet()
                            .toList();

                        final duplicatesInSameCenter = matchingMembers.where((other) {
                          if (other.memberId == member.memberId) return false;
                          if (other.id.isNotEmpty && member.id.isNotEmpty && other.id == member.id) return false;
                          return other.center.trim().toLowerCase() == member.center.trim().toLowerCase();
                        }).toList();

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: borderColor, width: 1.1),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.02),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Material(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(16),
                            clipBehavior: Clip.antiAlias,
                            child: ListTile(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => MemberDetailsScreen(
                                      member: member,
                                      allMembers: allMembers,
                                    ),
                                  ),
                                );
                              },
                              splashColor: primaryColor.withValues(alpha: 0.14),
                              hoverColor: primaryColor.withValues(alpha: 0.05),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            // Profile photo
                            leading: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isInactive
                                    ? Colors.grey.withValues(alpha: 0.15)
                                    : primaryColor.withValues(alpha: 0.12),
                                border: Border.all(
                                  color: isInactive
                                      ? Colors.grey.withValues(alpha: 0.3)
                                      : primaryColor.withValues(alpha: 0.3),
                                  width: 1.5,
                                ),
                                image: member.profileImageProvider != null
                                    ? DecorationImage(
                                        image: member.profileImageProvider!,
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: member.profileImageProvider == null
                                  ? Center(
                                      child: Text(
                                        member.firstName.isNotEmpty
                                            ? member.firstName[0].toUpperCase()
                                            : 'M',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: isInactive ? textSecondary : primaryColor,
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                            // Member Full Name
                            title: Text(
                              member.fullName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.bold,
                                color: isInactive ? textSecondary : textPrimary,
                              ),
                            ),
                            // Positions & Duplicate indicator
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 3.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    member.positionsSummary,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: isInactive ? textSecondary : primaryColor,
                                    ),
                                  ),
                                  if (otherCenters.isNotEmpty) ...[
                                    const SizedBox(height: 5),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7.5, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.withValues(alpha: isDark ? 0.22 : 0.12),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: Colors.amber.withValues(alpha: 0.5),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.warning_amber_rounded,
                                            size: 12,
                                            color: Colors.amber.shade900,
                                          ),
                                          const SizedBox(width: 4),
                                          Flexible(
                                            child: Text(
                                              'Duplicate: ${otherCenters.join(', ')}',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.amber.shade900,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ] else if (duplicatesInSameCenter.isNotEmpty) ...[
                                    const SizedBox(height: 5),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7.5, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.withValues(alpha: isDark ? 0.22 : 0.12),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: Colors.amber.withValues(alpha: 0.5),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.copy_rounded,
                                            size: 12,
                                            color: Colors.amber.shade900,
                                          ),
                                          const SizedBox(width: 4),
                                          Flexible(
                                            child: Text(
                                              'Duplicate: Same Center (${member.center.isNotEmpty ? member.center : "Local"})',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.amber.shade900,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            // Status Badge & Trailing Chevron
                            // Trailing Status / Completeness Badge (No Chevron)
                            trailing: isInactive
                                ? Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.08)
                                          : Colors.black.withValues(alpha: 0.06),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'Inactive',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: textSecondary,
                                      ),
                                    ),
                                  )
                                : Tooltip(
                                    message: isComplete
                                        ? 'Profile Complete'
                                        : 'Profile Incomplete (${member.missingFields.length} missing)',
                                    child: Container(
                                      padding: const EdgeInsets.all(5),
                                      decoration: BoxDecoration(
                                        color: isComplete
                                            ? Colors.green.withValues(alpha: isDark ? 0.2 : 0.12)
                                            : Colors.amber.withValues(alpha: isDark ? 0.2 : 0.14),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        isComplete
                                            ? Icons.check_circle_rounded
                                            : Icons.warning_amber_rounded,
                                        size: 15,
                                        color: isComplete ? Colors.green : Colors.amber.shade800,
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                      );
                      },
                      childCount: filteredMembers.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
