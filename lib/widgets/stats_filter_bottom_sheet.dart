import 'package:flutter/material.dart';
import '../models/center_model.dart';
import '../models/member.dart';

class StatsFilterCriteria {
  final String district;
  final String area;
  final String center;
  final String completenessPercentage; // 'All', '0%', '10%', '20%', '30%', '40%', '50%', '60%', '70%', '80%', '90%', '100%'
  final bool atLeastPercentage; // true: >= selected %, false: exact tier (e.g. 50%-59%)

  const StatsFilterCriteria({
    this.district = 'All Districts',
    this.area = 'All Areas',
    this.center = 'All Local Centers',
    this.completenessPercentage = 'All',
    this.atLeastPercentage = true,
  });

  bool get hasActiveFilter =>
      district != 'All Districts' ||
      area != 'All Areas' ||
      center != 'All Local Centers' ||
      completenessPercentage != 'All';

  int get activeFilterCount {
    int count = 0;
    if (district != 'All Districts') count++;
    if (area != 'All Areas') count++;
    if (center != 'All Local Centers') count++;
    if (completenessPercentage != 'All') count++;
    return count;
  }

  StatsFilterCriteria copyWith({
    String? district,
    String? area,
    String? center,
    String? completenessPercentage,
    bool? atLeastPercentage,
  }) {
    return StatsFilterCriteria(
      district: district ?? this.district,
      area: area ?? this.area,
      center: center ?? this.center,
      completenessPercentage: completenessPercentage ?? this.completenessPercentage,
      atLeastPercentage: atLeastPercentage ?? this.atLeastPercentage,
    );
  }
}

class StatsFilterBottomSheet extends StatefulWidget {
  final StatsFilterCriteria currentFilter;
  final List<CenterModel> allCenters;
  final Member? currentMember;
  final ValueChanged<StatsFilterCriteria> onApply;

  const StatsFilterBottomSheet({
    super.key,
    required this.currentFilter,
    required this.allCenters,
    this.currentMember,
    required this.onApply,
  });

  @override
  State<StatsFilterBottomSheet> createState() => _StatsFilterBottomSheetState();
}

class _StatsFilterBottomSheetState extends State<StatsFilterBottomSheet> {
  late String _selectedDistrict;
  late String _selectedArea;
  late String _selectedCenter;
  late String _selectedCompletenessPercentage;
  late bool _atLeastPercentage;

  static const List<String> percentageOptions = [
    'All',
    '0%',
    '10%',
    '20%',
    '30%',
    '40%',
    '50%',
    '60%',
    '70%',
    '80%',
    '90%',
    '100%',
  ];

  @override
  void initState() {
    super.initState();
    final user = widget.currentMember;
    if (user != null && user.isDistrictLocked && user.district.isNotEmpty) {
      _selectedDistrict = user.district;
    } else {
      _selectedDistrict = widget.currentFilter.district;
    }

    if (user != null && user.isAreaLocked && user.area.isNotEmpty) {
      _selectedArea = user.area;
    } else {
      _selectedArea = widget.currentFilter.area;
    }

    if (user != null && user.isCenterLocked && user.center.isNotEmpty) {
      _selectedCenter = user.center;
    } else {
      _selectedCenter = widget.currentFilter.center;
    }

    _selectedCompletenessPercentage = widget.currentFilter.completenessPercentage;
    _atLeastPercentage = widget.currentFilter.atLeastPercentage;
  }

  void _reset() {
    setState(() {
      final user = widget.currentMember;
      _selectedDistrict = (user != null && user.isDistrictLocked && user.district.isNotEmpty)
          ? user.district
          : 'All Districts';
      _selectedArea = (user != null && user.isAreaLocked && user.area.isNotEmpty)
          ? user.area
          : 'All Areas';
      _selectedCenter = (user != null && user.isCenterLocked && user.center.isNotEmpty)
          ? user.center
          : 'All Local Centers';
      _selectedCompletenessPercentage = 'All';
      _atLeastPercentage = true;
    });
  }

  void _apply() {
    final criteria = StatsFilterCriteria(
      district: _selectedDistrict,
      area: _selectedArea,
      center: _selectedCenter,
      completenessPercentage: _selectedCompletenessPercentage,
      atLeastPercentage: _atLeastPercentage,
    );
    widget.onApply(criteria);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final textPrimary = isDark ? const Color(0xFFF5F5FA) : const Color(0xFF0E0E14);
    final textSecondary = isDark ? const Color(0xFF9E9EAF) : const Color(0xFF6E6E82);
    final cardBg = isDark ? const Color(0xFF1E1E2A) : const Color(0xFFF2F2F7);
    final borderColor = isDark ? const Color(0xFF2E2E3E) : const Color(0xFFE2E2EA);

    final isDistrictLocked = widget.currentMember?.isDistrictLocked ?? false;
    final isAreaLocked = widget.currentMember?.isAreaLocked ?? false;
    final isCenterLocked = widget.currentMember?.isCenterLocked ?? false;

    // 1. Districts list
    final List<String> districtOptions = (isDistrictLocked && widget.currentMember != null)
        ? [widget.currentMember!.district]
        : [
            'All Districts',
            ...widget.allCenters
                .map((c) => c.district.trim())
                .where((d) => d.isNotEmpty)
                .toSet()
                .toList()
              ..sort(),
          ];

    // 2. Areas list (cascaded by district)
    final filteredForArea = widget.allCenters.where((c) {
      if (_selectedDistrict != 'All Districts') {
        return c.district.toLowerCase() == _selectedDistrict.toLowerCase();
      }
      return true;
    }).toList();

    final List<String> areaOptions = (isAreaLocked && widget.currentMember != null)
        ? [widget.currentMember!.area]
        : [
            'All Areas',
            ...filteredForArea
                .map((c) => c.area.trim())
                .where((a) => a.isNotEmpty)
                .toSet()
                .toList()
              ..sort(),
          ];

    // 3. Centers list (cascaded by district & area)
    final filteredForCenter = widget.allCenters.where((c) {
      final matchDistrict = _selectedDistrict == 'All Districts' ||
          c.district.toLowerCase() == _selectedDistrict.toLowerCase();
      final matchArea = _selectedArea == 'All Areas' ||
          c.area.toLowerCase() == _selectedArea.toLowerCase();
      return matchDistrict && matchArea;
    }).toList();

    final List<String> centerOptions = (isCenterLocked && widget.currentMember != null)
        ? [widget.currentMember!.center]
        : [
            'All Local Centers',
            ...filteredForCenter
                .map((c) => c.centerName.trim())
                .where((n) => n.isNotEmpty)
                .toSet()
                .toList()
              ..sort(),
          ];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle Bar
            Center(
              child: Container(
                width: 42,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Title and Reset Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filter Statistics',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: _reset,
                  child: const Text('Reset All'),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // District Selector
            _buildDropdown(
              label: 'District',
              value: districtOptions.contains(_selectedDistrict)
                  ? _selectedDistrict
                  : districtOptions.first,
              items: districtOptions,
              isDark: isDark,
              primaryColor: primaryColor,
              cardBg: cardBg,
              borderColor: borderColor,
              isLocked: isDistrictLocked,
              onChanged: isDistrictLocked
                  ? null
                  : (val) {
                      if (val != null) {
                        setState(() {
                          _selectedDistrict = val;
                          _selectedArea = 'All Areas';
                          _selectedCenter = 'All Local Centers';
                        });
                      }
                    },
            ),
            const SizedBox(height: 12),

            // Area Selector
            _buildDropdown(
              label: 'Area',
              value: areaOptions.contains(_selectedArea)
                  ? _selectedArea
                  : areaOptions.first,
              items: areaOptions,
              isDark: isDark,
              primaryColor: primaryColor,
              cardBg: cardBg,
              borderColor: borderColor,
              isLocked: isAreaLocked,
              onChanged: isAreaLocked
                  ? null
                  : (val) {
                      if (val != null) {
                        setState(() {
                          _selectedArea = val;
                          _selectedCenter = 'All Local Centers';
                        });
                      }
                    },
            ),
            const SizedBox(height: 12),

            // Local Center Selector
            _buildDropdown(
              label: 'Local Center',
              value: centerOptions.contains(_selectedCenter)
                  ? _selectedCenter
                  : centerOptions.first,
              items: centerOptions,
              isDark: isDark,
              primaryColor: primaryColor,
              cardBg: cardBg,
              borderColor: borderColor,
              isLocked: isCenterLocked,
              onChanged: isCenterLocked
                  ? null
                  : (val) {
                      if (val != null) {
                        setState(() {
                          _selectedCenter = val;
                        });
                      }
                    },
            ),
            const SizedBox(height: 18),

            // Profile Completeness Rate Percentage Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'PROFILE COMPLETENESS RATE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                    color: primaryColor,
                  ),
                ),
                if (_selectedCompletenessPercentage != 'All')
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _atLeastPercentage = true;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _atLeastPercentage
                                ? primaryColor.withValues(alpha: isDark ? 0.25 : 0.15)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: _atLeastPercentage ? primaryColor : borderColor,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            '≥ At least',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: _atLeastPercentage ? FontWeight.w700 : FontWeight.w500,
                              color: _atLeastPercentage ? primaryColor : textSecondary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _atLeastPercentage = false;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: !_atLeastPercentage
                                ? primaryColor.withValues(alpha: isDark ? 0.25 : 0.15)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: !_atLeastPercentage ? primaryColor : borderColor,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            'Exact',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: !_atLeastPercentage ? FontWeight.w700 : FontWeight.w500,
                              color: !_atLeastPercentage ? primaryColor : textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 10),

            // Percentage filter chips: All, 0%, 10%, 20%, ... 100%
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: percentageOptions.map((pct) {
                final isSelected = _selectedCompletenessPercentage == pct;
                return _buildPercentageChip(
                  label: pct,
                  isSelected: isSelected,
                  primaryColor: primaryColor,
                  isDark: isDark,
                  onSelected: () {
                    setState(() {
                      _selectedCompletenessPercentage = pct;
                    });
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // Apply Button
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _apply,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Apply Filters',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPercentageChip({
    required String label,
    required bool isSelected,
    required Color primaryColor,
    required bool isDark,
    required VoidCallback onSelected,
  }) {
    final borderColor = isDark ? const Color(0xFF2E2E3E) : const Color(0xFFE2E2EA);
    final textPrimary = isDark ? const Color(0xFFF5F5FA) : const Color(0xFF0E0E14);
    final cardBg = isDark ? const Color(0xFF1E1E2A) : const Color(0xFFF2F2F7);

    return InkWell(
      onTap: onSelected,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor.withValues(alpha: isDark ? 0.28 : 0.14)
              : cardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? primaryColor : borderColor,
            width: isSelected ? 1.5 : 1.1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected ? primaryColor : textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required bool isDark,
    required Color primaryColor,
    required Color cardBg,
    required Color borderColor,
    required ValueChanged<String?>? onChanged,
    bool isLocked = false,
  }) {
    final textPrimary = isDark ? const Color(0xFFF5F5FA) : const Color(0xFF0E0E14);
    final isFiltered = value != 'All Districts' &&
        value != 'All Areas' &&
        value != 'All Local Centers';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isFiltered ? primaryColor : (isDark ? Colors.white70 : Colors.black87),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isFiltered ? primaryColor.withValues(alpha: 0.8) : borderColor,
              width: isFiltered ? 1.4 : 1.1,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: items.contains(value) ? value : items.first,
              isExpanded: true,
              dropdownColor: isDark ? const Color(0xFF1E1E2A) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              icon: Icon(
                isLocked ? Icons.lock_outline_rounded : Icons.keyboard_arrow_down_rounded,
                size: isLocked ? 16 : 24,
                color: isLocked ? Colors.grey : (isFiltered ? primaryColor : (isDark ? Colors.white60 : Colors.black54)),
              ),
              onChanged: isLocked ? null : onChanged,
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: isFiltered && item == value ? FontWeight.w700 : FontWeight.w500,
                      color: isLocked
                          ? textPrimary.withValues(alpha: 0.5)
                          : (isFiltered && item == value ? primaryColor : textPrimary),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}
