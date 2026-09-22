import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../models/activity_log.dart';
import '../../models/member.dart';
import '../../services/firestore_service.dart';

class ActivityLogsScreen extends StatefulWidget {
  const ActivityLogsScreen({super.key});

  @override
  State<ActivityLogsScreen> createState() => _ActivityLogsScreenState();
}

class _ActivityLogsScreenState extends State<ActivityLogsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();

  String _selectedActionFilter = 'All'; // 'All', 'ADD', 'UPDATE', 'DELETE'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showLogDetails(ActivityLog log) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? const Color(0xFFF5F5FA) : const Color(0xFF0E0E14);
    final textSecondary = isDark ? const Color(0xFF9E9EAF) : const Color(0xFF6E6E82);
    final cardBg = isDark ? const Color(0xFF1E1E2A) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2E2E3E) : const Color(0xFFE5E5ED);
    final formattedDate = DateFormat('MMMM dd, yyyy • hh:mm:ss a').format(log.timestamp);

    final locationParts = <String>[];
    if (log.center.isNotEmpty) locationParts.add(log.center);
    if (log.area.isNotEmpty) locationParts.add(log.area);
    if (log.district.isNotEmpty) locationParts.add(log.district);
    final locationText = locationParts.isNotEmpty ? locationParts.join(' • ') : 'General / Unassigned';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
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

              // Action Badge & Close
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: log.actionColor.withValues(alpha: isDark ? 0.25 : 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: log.actionColor.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(log.actionIcon, size: 14, color: log.actionColor),
                        const SizedBox(width: 6),
                        Text(
                          log.actionDisplayName.toUpperCase(),
                          style: TextStyle(
                            color: log.actionColor,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.7,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 22),
                    color: textSecondary,
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              Text(
                log.description,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                formattedDate,
                style: TextStyle(
                  fontSize: 12.5,
                  color: textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 16),
              Divider(color: borderColor),
              const SizedBox(height: 12),

              _buildDetailItem(
                label: 'PERFORMED BY',
                value: '${log.performedByName} (${log.role.toUpperCase()})',
                subValue: log.performedByUid.isNotEmpty ? 'UID: ${log.performedByUid}' : null,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),

              _buildDetailItem(
                label: 'LOCATION / JURISDICTION',
                value: locationText,
                subValue: log.center.isNotEmpty
                    ? 'Center: ${log.center} | Area: ${log.area.isNotEmpty ? log.area : "N/A"} | District: ${log.district.isNotEmpty ? log.district : "N/A"}'
                    : null,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),

              _buildDetailItem(
                label: 'ACTION TYPE',
                value: log.action,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(
                      ClipboardData(
                        text:
                            'Action: ${log.action}\nDescription: ${log.description}\nPerformed By: ${log.performedByName} (${log.role})\nUID: ${log.performedByUid}\nJurisdiction: $locationText\nTimestamp: $formattedDate',
                      ),
                    );
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Log details copied to clipboard'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: const Text('Copy Audit Information'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: textPrimary,
                    side: BorderSide(color: borderColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem({
    required String label,
    required String value,
    String? subValue,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          if (subValue != null) ...[
            const SizedBox(height: 1),
            Text(
              subValue,
              style: TextStyle(
                fontSize: 12,
                color: textSecondary,
              ),
            ),
          ],
        ],
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
      appBar: AppBar(
        title: Text(
          'Activity Logs',
          style: TextStyle(
            color: textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
        scrolledUnderElevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          color: textPrimary,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: StreamBuilder<Member?>(
        stream: _firestoreService.getCurrentMemberStream(),
        builder: (context, memberSnapshot) {
          if (memberSnapshot.connectionState == ConnectionState.waiting && !memberSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final currentMember = memberSnapshot.data;
          final hasAccess = currentMember != null && currentMember.canViewActivityLogs;

          if (!hasAccess) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF2A55).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lock_person_rounded,
                        size: 48,
                        color: Color(0xFFFF2A55),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Access Restricted',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Activity logs are only accessible to Administrators and District Admins.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Return to Portal'),
                    ),
                  ],
                ),
              ),
            );
          }

          return StreamBuilder<List<ActivityLog>>(
            stream: _firestoreService.getActivityLogsStream(),
            builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final allLogs = snapshot.data ?? [];

          // Search & Action filtering
          final searchQuery = _searchController.text.trim().toLowerCase();
          final logs = allLogs.where((log) {
            // Action filter
            if (_selectedActionFilter != 'All') {
              final act = log.action.toUpperCase();
              if (_selectedActionFilter == 'ADD' && !act.contains('ADD') && !act.contains('CREATE')) {
                return false;
              }
              if (_selectedActionFilter == 'UPDATE' && !act.contains('UPDATE') && !act.contains('EDIT')) {
                return false;
              }
              if (_selectedActionFilter == 'DELETE' && !act.contains('DELETE') && !act.contains('REMOVE')) {
                return false;
              }
            }

            if (searchQuery.isEmpty) return true;
            final matchesDescription = log.description.toLowerCase().contains(searchQuery);
            final matchesActor = log.performedByName.toLowerCase().contains(searchQuery);
            final matchesUid = log.performedByUid.toLowerCase().contains(searchQuery);
            final matchesCenter = log.center.toLowerCase().contains(searchQuery);
            final matchesArea = log.area.toLowerCase().contains(searchQuery);
            final matchesDistrict = log.district.toLowerCase().contains(searchQuery);
            final matchesRole = log.role.toLowerCase().contains(searchQuery);
            final matchesAction = log.action.toLowerCase().contains(searchQuery);
            return matchesDescription ||
                matchesActor ||
                matchesUid ||
                matchesCenter ||
                matchesArea ||
                matchesDistrict ||
                matchesRole ||
                matchesAction;
          }).toList();

          final addedCount = allLogs.where((l) {
            final a = l.action.toUpperCase();
            return a.contains('ADD') || a.contains('CREATE');
          }).length;

          final updatedCount = allLogs.where((l) {
            final a = l.action.toUpperCase();
            return a.contains('UPDATE') || a.contains('EDIT');
          }).length;

          final deletedCount = allLogs.where((l) {
            final a = l.action.toUpperCase();
            return a.contains('DELETE') || a.contains('REMOVE');
          }).length;

          return CustomScrollView(
            slivers: [
              // Top Hero Card & Statistics
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: borderColor, width: 1.1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
                          blurRadius: 12,
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
                              'SYSTEM AUDIT TRAIL',
                              style: TextStyle(
                                color: primaryColor,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.4,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: primaryColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${allLogs.length} Events',
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
                          'Member Activity Log',
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Real-time administrative records of member registrations, profile updates, and removals.',
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Stats Summary Row
                        Row(
                          children: [
                            _buildStatBadge(
                              label: 'Added',
                              count: addedCount,
                              color: const Color(0xFF00C853),
                              isDark: isDark,
                            ),
                            const SizedBox(width: 8),
                            _buildStatBadge(
                              label: 'Updated',
                              count: updatedCount,
                              color: const Color(0xFFA100FF),
                              isDark: isDark,
                            ),
                            const SizedBox(width: 8),
                            _buildStatBadge(
                              label: 'Deleted',
                              count: deletedCount,
                              color: const Color(0xFFFF2A55),
                              isDark: isDark,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Search Box
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 6),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    style: TextStyle(fontSize: 14, color: textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Search description, admin, center, district...',
                      hintStyle: TextStyle(fontSize: 13, color: textSecondary),
                      prefixIcon: Icon(Icons.search_rounded, color: textSecondary, size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              color: textSecondary,
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: cardBg,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                        borderSide: BorderSide(color: primaryColor, width: 1.5),
                      ),
                    ),
                  ),
                ),
              ),

              // Action Filter Chips
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    children: [
                      _buildFilterChip('All', 'All', primaryColor, cardBg, borderColor, isDark),
                      const SizedBox(width: 8),
                      _buildFilterChip('Additions', 'ADD', const Color(0xFF00C853), cardBg, borderColor, isDark),
                      const SizedBox(width: 8),
                      _buildFilterChip('Updates', 'UPDATE', const Color(0xFFA100FF), cardBg, borderColor, isDark),
                      const SizedBox(width: 8),
                      _buildFilterChip('Deletions', 'DELETE', const Color(0xFFFF2A55), cardBg, borderColor, isDark),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 8)),

              // Logs List
              if (logs.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.history_rounded,
                          size: 52,
                          color: textSecondary.withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          allLogs.isEmpty
                              ? 'No Activity Logs Recorded Yet'
                              : 'No logs match your filter criteria',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Actions performed on member records will appear here.',
                          style: TextStyle(fontSize: 12.5, color: textSecondary),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 4, 18, 30),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final log = logs[index];

                        final locationPillParts = <String>[];
                        if (log.center.isNotEmpty) locationPillParts.add(log.center);
                        if (log.district.isNotEmpty) locationPillParts.add(log.district);
                        final locationPill = locationPillParts.join(' • ');

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: borderColor, width: 1.1),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: () => _showLogDetails(log),
                              splashColor: log.actionColor.withValues(alpha: 0.12),
                              hoverColor: log.actionColor.withValues(alpha: 0.04),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Action Icon Circle
                                    Container(
                                      width: 42,
                                      height: 42,
                                      decoration: BoxDecoration(
                                        color: log.actionColor.withValues(
                                          alpha: isDark ? 0.22 : 0.12,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        log.actionIcon,
                                        color: log.actionColor,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),

                                    // Details Column
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 7,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: log.actionColor.withValues(
                                                    alpha: isDark ? 0.2 : 0.1,
                                                  ),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  log.actionDisplayName.toUpperCase(),
                                                  style: TextStyle(
                                                    fontSize: 9.5,
                                                    fontWeight: FontWeight.w800,
                                                    letterSpacing: 0.5,
                                                    color: log.actionColor,
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                log.timeAgo,
                                                style: TextStyle(
                                                  fontSize: 11.5,
                                                  color: textSecondary,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            log.description,
                                            style: TextStyle(
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w700,
                                              color: textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'By ${log.performedByName} • ${log.role.toUpperCase()}',
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              color: textSecondary,
                                            ),
                                          ),
                                          if (locationPill.isNotEmpty) ...[
                                            const SizedBox(height: 3),
                                            Text(
                                              locationPill,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: textSecondary.withValues(alpha: 0.8),
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: logs.length,
                    ),
                  ),
                ),
            ],
          );
        },
      );
    },
  ),
);
}

  Widget _buildStatBadge({
    required String label,
    required int count,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.18 : 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            '$count $label',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    String actionKey,
    Color activeColor,
    Color cardBg,
    Color borderColor,
    bool isDark,
  ) {
    final isSelected = _selectedActionFilter == actionKey;

    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
        ),
      ),
      selected: isSelected,
      selectedColor: activeColor,
      backgroundColor: cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isSelected ? activeColor : borderColor,
          width: 1,
        ),
      ),
      showCheckmark: false,
      onSelected: (_) {
        setState(() {
          _selectedActionFilter = actionKey;
        });
      },
    );
  }
}
