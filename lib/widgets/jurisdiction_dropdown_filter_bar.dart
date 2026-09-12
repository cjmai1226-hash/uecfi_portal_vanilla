import 'package:flutter/material.dart';
import '../models/center_model.dart';
import '../models/member.dart';

class JurisdictionDropdownFilterBar extends StatelessWidget {
  final String selectedDistrict;
  final String selectedArea;
  final String selectedCenter;
  final List<CenterModel> allCenters;
  final Member? currentMember;
  final void Function(String district, String area, String center) onFilterChanged;
  final VoidCallback onResetFilters;

  const JurisdictionDropdownFilterBar({
    super.key,
    required this.selectedDistrict,
    required this.selectedArea,
    required this.selectedCenter,
    required this.allCenters,
    this.currentMember,
    required this.onFilterChanged,
    required this.onResetFilters,
  });

  String get userRole => currentMember?.role.toLowerCase() ?? 'admin';

  bool get isDistrictLocked => currentMember?.isDistrictLocked ?? false;

  bool get isAreaLocked => currentMember?.isAreaLocked ?? false;

  bool get isCenterLocked => currentMember?.isCenterLocked ?? false;

  bool get hasActiveFilter =>
      selectedDistrict != 'All Districts' ||
      selectedArea != 'All Areas' ||
      selectedCenter != 'All Local Centers';

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    // Resolve active selection based on role locks if present
    String activeDistrict = selectedDistrict;
    String activeArea = selectedArea;
    String activeCenter = selectedCenter;

    if (isDistrictLocked && currentMember != null && currentMember!.district.isNotEmpty) {
      activeDistrict = currentMember!.district;
    }
    if (isAreaLocked && currentMember != null && currentMember!.area.isNotEmpty) {
      activeArea = currentMember!.area;
    }
    if (isCenterLocked && currentMember != null && currentMember!.center.isNotEmpty) {
      activeCenter = currentMember!.center;
    }

    // 1. District options
    final List<String> districtOptions = isDistrictLocked && currentMember != null
        ? [currentMember!.district]
        : [
            'All Districts',
            ...allCenters
                .map((c) => c.district.trim())
                .where((d) => d.isNotEmpty)
                .toSet()
                .toList()
              ..sort(),
          ];

    // 2. Area options (scoped to active district)
    final filteredCentersForArea = allCenters.where((c) {
      if (activeDistrict != 'All Districts') {
        return c.district.toLowerCase() == activeDistrict.toLowerCase();
      }
      return true;
    }).toList();

    final List<String> availableAreas = isAreaLocked && currentMember != null
        ? [currentMember!.area]
        : [
            'All Areas',
            ...filteredCentersForArea
                .map((c) => c.area.trim())
                .where((a) => a.isNotEmpty)
                .toSet()
                .toList()
              ..sort(),
          ];

    // 3. Center options (scoped to active district & area)
    final filteredCentersForCenter = allCenters.where((c) {
      final matchDistrict = activeDistrict == 'All Districts' ||
          c.district.toLowerCase() == activeDistrict.toLowerCase();
      final matchArea = activeArea == 'All Areas' ||
          c.area.toLowerCase() == activeArea.toLowerCase();
      return matchDistrict && matchArea;
    }).toList();

    final List<String> availableCenters = isCenterLocked && currentMember != null
        ? [currentMember!.center]
        : [
            'All Local Centers',
            ...filteredCentersForCenter
                .map((c) => c.centerName.trim())
                .where((name) => name.isNotEmpty)
                .toSet()
                .toList()
              ..sort(),
          ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // District Dropdown
          _buildInlineDropdown(
            context,
            prefix: 'District',
            value: activeDistrict,
            items: districtOptions,
            isLocked: isDistrictLocked,
            onChanged: isDistrictLocked
                ? null
                : (val) {
                    if (val != null) {
                      onFilterChanged(
                        val,
                        'All Areas',
                        'All Local Centers',
                      );
                    }
                  },
          ),
          const SizedBox(width: 8),

          // Area Dropdown
          _buildInlineDropdown(
            context,
            prefix: 'Area',
            value: activeArea,
            items: availableAreas,
            isLocked: isAreaLocked,
            onChanged: isAreaLocked
                ? null
                : (val) {
                    if (val != null) {
                      onFilterChanged(
                        activeDistrict,
                        val,
                        'All Local Centers',
                      );
                    }
                  },
          ),
          const SizedBox(width: 8),

          // Local Center Dropdown
          _buildInlineDropdown(
            context,
            prefix: 'Center',
            value: activeCenter,
            items: availableCenters,
            isLocked: isCenterLocked,
            onChanged: isCenterLocked
                ? null
                : (val) {
                    if (val != null) {
                      onFilterChanged(
                        activeDistrict,
                        activeArea,
                        val,
                      );
                    }
                  },
          ),

          // Reset Button (if active filter and not center-locked)
          if (hasActiveFilter && !isCenterLocked) ...[
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: onResetFilters,
              icon: const Icon(Icons.refresh_rounded, size: 15),
              label: const Text(
                'Reset',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              style: TextButton.styleFrom(
                foregroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                minimumSize: const Size(0, 36),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInlineDropdown(
    BuildContext context, {
    required String prefix,
    required String value,
    required List<String> items,
    required bool isLocked,
    required ValueChanged<String?>? onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final textPrimary = isDark ? const Color(0xFFF5F5FA) : const Color(0xFF0E0E14);
    final textMuted = isDark ? const Color(0xFF9E9EAF) : const Color(0xFF6E6E82);
    final cardBg = isDark ? const Color(0xFF16161F) : Colors.white;
    final borderColor = isDark ? const Color(0xFF262633) : const Color(0xFFE5E5ED);

    final isFiltered = value != 'All Districts' &&
        value != 'All Areas' &&
        value != 'All Local Centers';

    final safeValue = items.contains(value) ? value : (items.isNotEmpty ? items.first : null);

    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 11),
      decoration: BoxDecoration(
        color: isFiltered
            ? primaryColor.withValues(alpha: isDark ? 0.22 : 0.10)
            : cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isFiltered
              ? primaryColor.withValues(alpha: 0.6)
              : borderColor,
          width: isFiltered ? 1.4 : 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: safeValue,
          isDense: true,
          dropdownColor: cardBg,
          borderRadius: BorderRadius.circular(12),
          icon: Padding(
            padding: const EdgeInsets.only(left: 6),
            child: Icon(
              isLocked
                  ? Icons.lock_outline_rounded
                  : Icons.keyboard_arrow_down_rounded,
              color: isFiltered ? primaryColor : textMuted,
              size: 17,
            ),
          ),
          onChanged: isLocked ? null : onChanged,
          items: items.map((String item) {
            final displayText = item.startsWith('All') ? item : '$prefix: $item';
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                displayText,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isFiltered ? FontWeight.w700 : FontWeight.w500,
                  color: isFiltered ? primaryColor : textPrimary,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
