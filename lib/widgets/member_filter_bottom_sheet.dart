import 'package:flutter/material.dart';
import '../models/center_model.dart';
import '../models/member.dart';

class MemberFilterCriteria {
  final String district;
  final String area;
  final String center;
  final String status; // 'All', 'Active', 'Inactive'
  final String completeness; // 'All', 'Complete', 'Incomplete'
  final bool duplicatesOnly;

  const MemberFilterCriteria({
    this.district = 'All Districts',
    this.area = 'All Areas',
    this.center = 'All Local Centers',
    this.status = 'All',
    this.completeness = 'All',
    this.duplicatesOnly = false,
  });

  bool get hasActiveFilter =>
      district != 'All Districts' ||
      area != 'All Areas' ||
      center != 'All Local Centers' ||
      status != 'All' ||
      completeness != 'All' ||
      duplicatesOnly;

  int get activeFilterCount {
    int count = 0;
    if (district != 'All Districts') count++;
    if (area != 'All Areas') count++;
    if (center != 'All Local Centers') count++;
    if (status != 'All') count++;
    if (completeness != 'All') count++;
    if (duplicatesOnly) count++;
    return count;
  }

  MemberFilterCriteria copyWith({
    String? district,
    String? area,
    String? center,
    String? status,
    String? completeness,
    bool? duplicatesOnly,
  }) {
    return MemberFilterCriteria(
      district: district ?? this.district,
      area: area ?? this.area,
      center: center ?? this.center,
      status: status ?? this.status,
      completeness: completeness ?? this.completeness,
      duplicatesOnly: duplicatesOnly ?? this.duplicatesOnly,
    );
  }
}

class MemberFilterBottomSheet extends StatefulWidget {
  final MemberFilterCriteria currentFilter;
  final List<CenterModel> allCenters;
  final Member? currentMember;
  final ValueChanged<MemberFilterCriteria> onApply;

  const MemberFilterBottomSheet({
    super.key,
    required this.currentFilter,
    required this.allCenters,
    this.currentMember,
    required this.onApply,
  });

  @override
  State<MemberFilterBottomSheet> createState() => _MemberFilterBottomSheetState();
}

class _MemberFilterBottomSheetState extends State<MemberFilterBottomSheet> {
  late String _selectedDistrict;
  late String _selectedArea;
  late String _selectedCenter;
  late String _selectedStatus;
  late String _selectedCompleteness;
  late bool _selectedDuplicatesOnly;

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

    _selectedStatus = widget.currentFilter.status;
    _selectedCompleteness = widget.currentFilter.completeness;
    _selectedDuplicatesOnly = widget.currentFilter.duplicatesOnly;
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
      _selectedStatus = 'All';
      _selectedCompleteness = 'All';
      _selectedDuplicatesOnly = false;
    });
  }

  void _apply() {
    final criteria = MemberFilterCriteria(
      district: _selectedDistrict,
      area: _selectedArea,
      center: _selectedCenter,
      status: _selectedStatus,
      completeness: _selectedCompleteness,
      duplicatesOnly: _selectedDuplicatesOnly,
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
                  'Filter Members',
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
              cardBg: cardBg,
              borderColor: borderColor,
              textPrimary: textPrimary,
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
              cardBg: cardBg,
              borderColor: borderColor,
              textPrimary: textPrimary,
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
              cardBg: cardBg,
              borderColor: borderColor,
              textPrimary: textPrimary,
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
            const SizedBox(height: 16),

            // Status Filter Chips
            Text(
              'MEMBERSHIP STATUS',
              style: TextStyle(
                color: primaryColor,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildFilterChip('All', _selectedStatus == 'All', (sel) {
                  setState(() => _selectedStatus = 'All');
                }),
                const SizedBox(width: 8),
                _buildFilterChip('Active', _selectedStatus == 'Active', (sel) {
                  setState(() => _selectedStatus = 'Active');
                }),
                const SizedBox(width: 8),
                _buildFilterChip('Inactive', _selectedStatus == 'Inactive', (sel) {
                  setState(() => _selectedStatus = 'Inactive');
                }),
              ],
            ),
            const SizedBox(height: 16),

            // Completeness Filter Chips
            Text(
              'PROFILE COMPLETENESS',
              style: TextStyle(
                color: primaryColor,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildFilterChip('All', _selectedCompleteness == 'All', (sel) {
                  setState(() => _selectedCompleteness = 'All');
                }),
                const SizedBox(width: 8),
                _buildFilterChip('Complete', _selectedCompleteness == 'Complete', (sel) {
                  setState(() => _selectedCompleteness = 'Complete');
                }),
                const SizedBox(width: 8),
                _buildFilterChip('Incomplete', _selectedCompleteness == 'Incomplete', (sel) {
                  setState(() => _selectedCompleteness = 'Incomplete');
                }),
              ],
            ),
            const SizedBox(height: 16),

            // Duplicate Records Filter Chips
            Text(
              'DUPLICATE RECORDS',
              style: TextStyle(
                color: primaryColor,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildFilterChip('All Records', !_selectedDuplicatesOnly, (sel) {
                  setState(() => _selectedDuplicatesOnly = false);
                }),
                const SizedBox(width: 8),
                _buildFilterChip('Duplicates Only', _selectedDuplicatesOnly, (sel) {
                  setState(() => _selectedDuplicatesOnly = true);
                }),
              ],
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
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required Color cardBg,
    required Color borderColor,
    required Color textPrimary,
    required ValueChanged<String?>? onChanged,
    bool isLocked = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1.1),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1E1E2A)
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          icon: Icon(
            isLocked ? Icons.lock_outline_rounded : Icons.keyboard_arrow_down_rounded,
            size: isLocked ? 16 : 24,
            color: isLocked ? Colors.grey : null,
          ),
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: item.startsWith('All ') ? FontWeight.w500 : FontWeight.w600,
                  color: isLocked ? textPrimary.withValues(alpha: 0.5) : textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: isLocked ? null : onChanged,
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, ValueChanged<bool> onSelected) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Expanded(
      child: ChoiceChip(
        label: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? Colors.white : null,
            ),
          ),
        ),
        selected: isSelected,
        selectedColor: primaryColor,
        showCheckmark: false,
        onSelected: onSelected,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
