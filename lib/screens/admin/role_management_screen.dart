import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/member.dart';
import '../../services/firestore_service.dart';

class RoleManagementScreen extends StatefulWidget {
  const RoleManagementScreen({super.key});

  @override
  State<RoleManagementScreen> createState() => _RoleManagementScreenState();
}

class _RoleManagementScreenState extends State<RoleManagementScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();
  final NumberFormat _countFormat = NumberFormat('#,##0', 'en_US');

  // Filter keys: 'All', 'admin', 'district', 'area', 'local', 'member'
  String _selectedRoleFilter = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return const Color(0xFFA100FF);
      case 'district':
      case 'district_admin':
      case 'district admin':
        return const Color(0xFF00B0FF);
      case 'area':
        return const Color(0xFFFF9100);
      case 'local':
        return const Color(0xFF00C853);
      case 'member':
      default:
        return const Color(0xFF88849E);
    }
  }

  String _getRoleLabel(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return 'Administrator';
      case 'district':
      case 'district_admin':
      case 'district admin':
        return 'District Admin';
      case 'area':
        return 'Area Coordinator';
      case 'local':
        return 'Local Officer';
      case 'member':
      default:
        return 'Church Member';
    }
  }

  void _showRoleAssignmentSheet(
    BuildContext context,
    Member member, {
    required bool canAssign,
  }) {
    if (!canAssign) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.info_outline_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text('Only Administrators have permission to assign or change member roles.'),
              ),
            ],
          ),
          backgroundColor: Color(0xFFE65100),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _RoleAssignmentModal(
          member: member,
          onRoleUpdated: (newRole) async {
            await _firestoreService.updateMemberRole(
              docId: member.id,
              role: newRole,
              memberName: member.fullName,
              memberId: member.memberId,
              district: member.district,
              area: member.area,
              center: member.center,
            );
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text('Assigned ${member.firstName} as ${_getRoleLabel(newRole)}'),
                      ),
                    ],
                  ),
                  backgroundColor: const Color(0xFF00C853),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
        );
      },
    );
  }

  Widget _buildRoleFilterChip(
    BuildContext context,
    String key, {
    required String label,
    int? count,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _selectedRoleFilter == key;
    final textSecondary = isDark ? const Color(0xFF9E9EAF) : const Color(0xFF6E6E82);
    final borderColor = isDark ? const Color(0xFF262633) : const Color(0xFFE5E5ED);
    final cardBg = isDark ? const Color(0xFF16161F) : Colors.white;

    final displayText = count != null ? '$label (${_countFormat.format(count)})' : label;

    Color activeColor = const Color(0xFFA100FF);
    if (key != 'All') {
      activeColor = _getRoleColor(key);
    }

    return ChoiceChip(
      label: Text(displayText),
      selected: isSelected,
      visualDensity: VisualDensity.compact,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedRoleFilter = key;
          });
        }
      },
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : textSecondary,
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
      ),
      selectedColor: activeColor,
      backgroundColor: cardBg,
      side: BorderSide(
        color: isSelected ? activeColor : borderColor,
        width: isSelected ? 1.4 : 1.0,
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

    return StreamBuilder<Member?>(
      stream: _firestoreService.getCurrentMemberStream(),
      builder: (context, memberSnapshot) {
        if (memberSnapshot.connectionState == ConnectionState.waiting && !memberSnapshot.hasData) {
          return Scaffold(
            appBar: AppBar(
              title: Text(
                'Role Management',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                color: textPrimary,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final currentMember = memberSnapshot.data;
        final hasAccess = currentMember != null && currentMember.isAdmin;

        // Access guard: strictly only System Administrators can access Role Management
        if (!hasAccess) {
          return Scaffold(
            appBar: AppBar(
              title: Text(
                'Role Management',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                color: textPrimary,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            body: Center(
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
                      'Role Management is strictly accessible to System Administrators.',
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
            ),
          );
        }

        final canAssign = currentMember.canAssignRoles;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Role Management',
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
          body: StreamBuilder<List<Member>>(
            stream: _firestoreService.getMembersStream(),
            builder: (context, snapshot) {
              final members = snapshot.data ?? [];
              final query = _searchController.text.trim().toLowerCase();

              // Counts per role
              final adminCount = members.where((m) => m.role.toLowerCase() == 'admin').length;
              final districtCount = members.where((m) {
                final r = m.role.toLowerCase();
                return r == 'district' || r == 'district_admin' || r == 'district admin';
              }).length;
              final areaCount = members.where((m) => m.role.toLowerCase() == 'area').length;
              final localCount = members.where((m) => m.role.toLowerCase() == 'local').length;
              final memberCount = members.where((m) {
                final r = m.role.toLowerCase();
                return r == 'member' ||
                    r.isEmpty ||
                    (r != 'admin' &&
                        r != 'district' &&
                        r != 'district_admin' &&
                        r != 'district admin' &&
                        r != 'area' &&
                        r != 'local');
              }).length;

              // Filtered members
              final filteredMembers = members.where((m) {
                final matchesQuery = query.isEmpty ||
                    m.fullName.toLowerCase().contains(query) ||
                    m.memberId.toLowerCase().contains(query) ||
                    m.center.toLowerCase().contains(query) ||
                    m.district.toLowerCase().contains(query) ||
                    m.area.toLowerCase().contains(query) ||
                    m.role.toLowerCase().contains(query);

                bool matchesRole = true;
                final mRole = m.role.toLowerCase();
                if (_selectedRoleFilter == 'admin') {
                  matchesRole = mRole == 'admin';
                } else if (_selectedRoleFilter == 'district') {
                  matchesRole = mRole == 'district' ||
                      mRole == 'district_admin' ||
                      mRole == 'district admin';
                } else if (_selectedRoleFilter == 'area') {
                  matchesRole = mRole == 'area';
                } else if (_selectedRoleFilter == 'local') {
                  matchesRole = mRole == 'local';
                } else if (_selectedRoleFilter == 'member') {
                  matchesRole = mRole == 'member' ||
                      mRole.isEmpty ||
                      (mRole != 'admin' &&
                          mRole != 'district' &&
                          mRole != 'district_admin' &&
                          mRole != 'district admin' &&
                          mRole != 'area' &&
                          mRole != 'local');
                }

                return matchesQuery && matchesRole;
              }).toList();

              return Column(
                children: [
                  // Search Box
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        style: TextStyle(color: textPrimary, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Search by member name, ID, center, or role...',
                          hintStyle: TextStyle(color: textSecondary, fontSize: 13),
                          prefixIcon: Icon(Icons.search_rounded, size: 20, color: primaryColor),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {});
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                    ),
                  ),

                  // Role Filter Chips Row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildRoleFilterChip(
                            context,
                            'All',
                            label: 'All',
                            count: members.length,
                          ),
                          const SizedBox(width: 6),
                          _buildRoleFilterChip(
                            context,
                            'admin',
                            label: 'Admin',
                            count: adminCount,
                          ),
                          const SizedBox(width: 6),
                          _buildRoleFilterChip(
                            context,
                            'district',
                            label: 'District',
                            count: districtCount,
                          ),
                          const SizedBox(width: 6),
                          _buildRoleFilterChip(
                            context,
                            'area',
                            label: 'Area',
                            count: areaCount,
                          ),
                          const SizedBox(width: 6),
                          _buildRoleFilterChip(
                            context,
                            'local',
                            label: 'Local',
                            count: localCount,
                          ),
                          const SizedBox(width: 6),
                          _buildRoleFilterChip(
                            context,
                            'member',
                            label: 'Member',
                            count: memberCount,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Members List
                  Expanded(
                    child: () {
                      if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (filteredMembers.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.person_search_outlined,
                                size: 48,
                                color: textSecondary.withValues(alpha: 0.6),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'No members found matching "$_selectedRoleFilter".',
                                style: TextStyle(color: textSecondary, fontSize: 13.5),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: filteredMembers.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final member = filteredMembers[index];
                          final roleColor = _getRoleColor(member.role);
                          final roleLabel = _getRoleLabel(member.role);

                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: borderColor, width: 1.1),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                // Avatar
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor: roleColor.withValues(alpha: 0.15),
                                  backgroundImage: member.profileImageProvider,
                                  child: member.profileImageProvider == null
                                      ? Text(
                                          member.initials,
                                          style: TextStyle(
                                            color: roleColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 12),

                                // Details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              member.fullName,
                                              style: TextStyle(
                                                fontSize: 14.5,
                                                fontWeight: FontWeight.w700,
                                                color: textPrimary,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 7,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: roleColor.withValues(alpha: isDark ? 0.22 : 0.12),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(
                                                color: roleColor.withValues(alpha: 0.35),
                                              ),
                                            ),
                                            child: Text(
                                              roleLabel.toUpperCase(),
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w700,
                                                color: roleColor,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        '${member.memberId} • ${member.center.isNotEmpty ? member.center : "Unassigned Center"}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: textSecondary,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // Assign / Edit Role Action
                                IconButton(
                                  tooltip: canAssign ? 'Change Role' : 'View Role',
                                  icon: Icon(
                                    canAssign ? Icons.edit_note_rounded : Icons.info_outline_rounded,
                                    size: 22,
                                    color: canAssign ? primaryColor : textSecondary,
                                  ),
                                  onPressed: () => _showRoleAssignmentSheet(
                                    context,
                                    member,
                                    canAssign: canAssign,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    }(),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _RoleAssignmentModal extends StatefulWidget {
  final Member member;
  final Function(String role) onRoleUpdated;

  const _RoleAssignmentModal({
    required this.member,
    required this.onRoleUpdated,
  });

  @override
  State<_RoleAssignmentModal> createState() => _RoleAssignmentModalState();
}

class _RoleAssignmentModalState extends State<_RoleAssignmentModal> {
  late String _selectedRole;
  bool _isSaving = false;

  final List<Map<String, dynamic>> _roleDefinitions = [
    {
      'role': 'admin',
      'label': 'Administrator',
      'description': 'Full access across all Districts, Areas, and Local Centers.',
      'color': const Color(0xFFA100FF),
      'icon': Icons.admin_panel_settings_rounded,
    },
    {
      'role': 'district',
      'label': 'District Admin',
      'description': 'District-wide: Announcements, activity logs, directory, and statistics.',
      'color': const Color(0xFF00B0FF),
      'icon': Icons.corporate_fare_rounded,
    },
    {
      'role': 'area',
      'label': 'Area Coordinator',
      'description': 'Area-wide: Manage members and monitor centers under assigned area.',
      'color': const Color(0xFFFF9100),
      'icon': Icons.hub_rounded,
    },
    {
      'role': 'local',
      'label': 'Local Center Officer',
      'description': 'Local-only: View and manage members belonging to local church center.',
      'color': const Color(0xFF00C853),
      'icon': Icons.church_rounded,
    },
    {
      'role': 'member',
      'label': 'Church Member',
      'description': 'Standard access to personal profile, announcements, forms, and bylaws.',
      'color': const Color(0xFF88849E),
      'icon': Icons.person_rounded,
    },
  ];

  @override
  void initState() {
    super.initState();
    final current = widget.member.role.toLowerCase().trim();
    if (current == 'district_admin' || current == 'district admin') {
      _selectedRole = 'district';
    } else {
      _selectedRole = current;
    }
    final validRoles = _roleDefinitions.map((r) => r['role'] as String).toList();
    if (!validRoles.contains(_selectedRole)) {
      _selectedRole = 'member';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final textPrimary = isDark ? const Color(0xFFF5F5FA) : const Color(0xFF0E0E14);
    final textSecondary = isDark ? const Color(0xFF9E9EAF) : const Color(0xFF6E6E82);
    final cardBg = isDark ? const Color(0xFF16161F) : Colors.white;
    final surfaceElevated = isDark ? const Color(0xFF1E1E2A) : const Color(0xFFF7F7FA);
    final borderColor = isDark ? const Color(0xFF262633) : const Color(0xFFE5E5ED);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
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

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.admin_panel_settings_rounded,
                    color: primaryColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Assign Member Role',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${widget.member.fullName} (${widget.member.memberId})',
                        style: TextStyle(
                          fontSize: 12,
                          color: textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Role Options List
            ...List.generate(_roleDefinitions.length, (index) {
              final def = _roleDefinitions[index];
              final roleKey = def['role'] as String;
              final label = def['label'] as String;
              final desc = def['description'] as String;
              final color = def['color'] as Color;
              final icon = def['icon'] as IconData;

              final isSelected = _selectedRole == roleKey;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedRole = roleKey;
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? color.withValues(alpha: isDark ? 0.18 : 0.10)
                          : surfaceElevated,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? color : borderColor,
                        width: isSelected ? 1.6 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(icon, color: color, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                label,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected ? color : textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                desc,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: textSecondary,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.check_circle_rounded, color: color, size: 20),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }),

            const SizedBox(height: 16),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                icon: _isSaving
                    ? const SizedBox.shrink()
                    : const Icon(Icons.check_circle_rounded, size: 18),
                label: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'SAVE ROLE ASSIGNMENT',
                        style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.4),
                      ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: _isSaving
                    ? null
                    : () async {
                        final nav = Navigator.of(context);
                        setState(() {
                          _isSaving = true;
                        });
                        try {
                          await widget.onRoleUpdated(_selectedRole);
                          if (mounted) {
                            setState(() {
                              _isSaving = false;
                            });
                            nav.pop();
                          }
                        } catch (_) {
                          if (mounted) {
                            setState(() {
                              _isSaving = false;
                            });
                          }
                        }
                      },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
