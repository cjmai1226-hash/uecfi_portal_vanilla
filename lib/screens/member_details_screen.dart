import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/member.dart';
import '../models/transfer_request.dart';
import '../services/firestore_service.dart';
import '../widgets/transfer_history_sheet.dart';
import 'add_member_screen.dart';
import 'transfer_request_screen.dart';

class MemberDetailsScreen extends StatefulWidget {
  final Member member;
  final List<Member>? allMembers;

  const MemberDetailsScreen({
    super.key,
    required this.member,
    this.allMembers,
  });

  @override
  State<MemberDetailsScreen> createState() => _MemberDetailsScreenState();
}

class _MemberDetailsScreenState extends State<MemberDetailsScreen> {
  late Member _currentMember;
  List<Member> _allMembers = [];

  @override
  void initState() {
    super.initState();
    _currentMember = widget.member;
    if (widget.allMembers != null && widget.allMembers!.isNotEmpty) {
      _allMembers = widget.allMembers!;
    } else {
      FirestoreService().getMembersOnce().then((list) {
        if (mounted) {
          setState(() {
            _allMembers = list;
          });
        }
      }).catchError((_) {});
    }
  }

  Future<void> _refreshMember() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('members').doc(_currentMember.id).get();
      if (doc.exists && mounted) {
        setState(() {
          _currentMember = Member.fromFirestore(doc);
        });
      }
    } catch (_) {}
  }

  void _confirmDeleteMember(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Member Record?'),
        content: Text(
          'Are you sure you want to permanently remove "${_currentMember.fullName}" from the district roster? This action will be recorded in the activity audit trail.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF2A55),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await FirestoreService().deleteMember(_currentMember);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Member ${_currentMember.fullName} deleted.'),
                      backgroundColor: const Color(0xFFFF2A55),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  Navigator.of(context).pop();
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete member: $e'),
                      backgroundColor: const Color(0xFFFF2A55),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: const Text('Delete Record'),
          ),
        ],
      ),
    );
  }

  Widget _buildImageView(String url, {BoxFit fit = BoxFit.contain}) {
    if (url.startsWith('data:image') || !url.startsWith('http')) {
      try {
        final raw = url.contains(',') ? url.split(',').last : url;
        return Image.memory(
          base64Decode(raw),
          fit: fit,
          errorBuilder: (context, error, stackTrace) => Container(
            height: 200,
            alignment: Alignment.center,
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.broken_image_rounded,
                  size: 40,
                  color: Colors.redAccent,
                ),
                SizedBox(height: 8),
                Text('Image could not be loaded'),
              ],
            ),
          ),
        );
      } catch (_) {
        return Container(
          height: 200,
          alignment: Alignment.center,
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.broken_image_rounded,
                size: 40,
                color: Colors.redAccent,
              ),
              SizedBox(height: 8),
              Text('Image could not be loaded'),
            ],
          ),
        );
      }
    }

    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      placeholder: (context, url) => const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        height: 200,
        alignment: Alignment.center,
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.broken_image_rounded,
              size: 40,
              color: Colors.redAccent,
            ),
            SizedBox(height: 8),
            Text(
              'Image could not be loaded',
              style: TextStyle(fontSize: 12, color: Colors.redAccent),
            ),
          ],
        ),
      ),
    );
  }

  void _openImageViewer(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String imageUrl,
    bool isSignature = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Row with Title & Close button
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E2A) : Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isSignature
                            ? Icons.draw_rounded
                            : Icons.account_circle_rounded,
                        color: primaryColor,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'Close',
                    ),
                  ],
                ),
              ),

              // Image Area with Zoom / Pan (InteractiveViewer)
              Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.65,
                  maxWidth: double.infinity,
                ),
                decoration: BoxDecoration(
                  color: isSignature
                      ? Colors.white
                      : (isDark ? Colors.black : const Color(0xFF1E1B2E)),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(16),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(16),
                  ),
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: _buildImageView(imageUrl),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final member = _currentMember;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isInactive = member.isInactive;

    final duplicates = _allMembers.where((other) {
      if (other.memberId == member.memberId) return false;
      if (other.id.isNotEmpty && member.id.isNotEmpty && other.id == member.id) return false;
      return member.isDuplicateNameOf(other);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Member Profile'),
        elevation: 0,
        scrolledUnderElevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          StreamBuilder<Member?>(
            stream: FirestoreService().getCurrentMemberStream(),
            builder: (context, snapshot) {
              final loggedInMember = snapshot.data;
              final currentUser = FirebaseAuth.instance.currentUser;
              final userRole = loggedInMember?.role.toLowerCase() ?? 'admin';
              final isAdmin = userRole == 'admin';

              final isSelf = (loggedInMember != null &&
                      (member.id == loggedInMember.id || member.memberId == loggedInMember.memberId)) ||
                  (currentUser?.email != null &&
                      member.email.trim().toLowerCase() == currentUser!.email!.trim().toLowerCase());

              final isDistrictMatch = loggedInMember != null &&
                  loggedInMember.district.isNotEmpty &&
                  loggedInMember.district.toLowerCase() == member.district.toLowerCase();

              final isAreaMatch = isDistrictMatch &&
                  loggedInMember.area.isNotEmpty &&
                  loggedInMember.area.toLowerCase() == member.area.toLowerCase();

              final isCenterMatch = isAreaMatch &&
                  loggedInMember.center.isNotEmpty &&
                  loggedInMember.center.toLowerCase() == member.center.toLowerCase();

              bool canEdit = false;
              if (isAdmin) {
                canEdit = true;
              } else if (userRole == 'district') {
                canEdit = isDistrictMatch;
              } else if (userRole == 'area') {
                canEdit = isAreaMatch;
              } else if (userRole == 'local') {
                canEdit = isCenterMatch;
              } else {
                // Regular member
                canEdit = isSelf;
              }

              final canDelete = isAdmin ||
                  (userRole == 'district' && isDistrictMatch) ||
                  (userRole == 'area' && isAreaMatch) ||
                  (userRole == 'local' && isCenterMatch);

              if (!canEdit && !canDelete) {
                return const SizedBox(width: 8);
              }

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (canEdit)
                    IconButton(
                      icon: const Icon(Icons.edit_rounded, size: 20),
                      tooltip: 'Edit Profile',
                      onPressed: () async {
                        final updated = await Navigator.of(context).push<Member>(
                          MaterialPageRoute(
                            builder: (_) => AddMemberScreen(memberToEdit: _currentMember),
                          ),
                        );
                        if (updated != null && mounted) {
                          setState(() {
                            _currentMember = updated;
                          });
                        }
                      },
                    ),
                  if (canDelete)
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Color(0xFFFF2A55)),
                      tooltip: 'Delete Record',
                      onPressed: () => _confirmDeleteMember(context),
                    ),
                ],
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Hero Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Center(
                      child: GestureDetector(
                        onTap: member.profileUrl.isNotEmpty
                            ? () => _openImageViewer(
                                  context,
                                  title: member.fullName,
                                  subtitle: 'Profile Photo',
                                  imageUrl: member.profileUrl,
                                )
                            : null,
                        child: Stack(
                          children: [
                            Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isInactive ? Colors.grey : primaryColor,
                                  width: 2.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: (isInactive ? Colors.grey : primaryColor)
                                        .withValues(alpha: isDark ? 0.35 : 0.2),
                                    blurRadius: 16,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                                image: member.profileImageProvider != null
                                    ? DecorationImage(
                                        image: member.profileImageProvider!,
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                                color: primaryColor.withValues(alpha: 0.12),
                              ),
                              child: member.profileUrl.isEmpty
                                  ? Center(
                                      child: Text(
                                        member.firstName.isNotEmpty
                                            ? member.firstName[0].toUpperCase()
                                            : 'M',
                                        style: TextStyle(
                                          color: isInactive ? Colors.grey : primaryColor,
                                          fontSize: 36,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                            if (member.profileUrl.isNotEmpty)
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color: primaryColor,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isDark
                                          ? const Color(0xFF1E1E2A)
                                          : Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.fullscreen_rounded,
                                    size: 13,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Full Name
                    Text(
                      member.fullName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Primary Position
                    Text(
                      member.primaryRole,
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // ID Badge & Status Pills Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Member ID
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3.5,
                          ),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: isDark ? 0.2 : 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            member.memberId,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Membership Status (Active / Inactive)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3.5,
                          ),
                          decoration: BoxDecoration(
                            color: isInactive
                                ? Colors.grey.withValues(alpha: 0.18)
                                : Colors.green.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            member.membershipStatus.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isInactive
                                  ? (isDark ? Colors.white70 : Colors.black54)
                                  : Colors.green.shade700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Member Type (Regular / Old / New)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3.5,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF262633)
                                : const Color(0xFFEFEFF4),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            member.memberType,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Duplicate Record Detected Banner
            if (duplicates.isNotEmpty) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: isDark ? 0.18 : 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.amber.withValues(alpha: 0.5),
                    width: 1.2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.amber.shade900,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'DUPLICATE RECORD DETECTED',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: Colors.amber.shade900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Another member with the identical full name (${member.fullName}) was found in the church registry:',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white70 : Colors.black87,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...duplicates.map((dup) {
                      final isOtherCenter = dup.center.trim().toLowerCase() != member.center.trim().toLowerCase();
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.amber.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.amber.withValues(alpha: isDark ? 0.25 : 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.location_on_rounded,
                                size: 16,
                                color: Colors.amber.shade900,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          dup.center.isNotEmpty ? dup.center : 'Unassigned Center',
                                          style: const TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (isOtherCenter)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.amber.shade700,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Text(
                                            'Other Center',
                                            style: TextStyle(
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${dup.district} • ${dup.area}  |  ID: ${dup.memberId}  |  ${dup.primaryRole}',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: isDark ? Colors.white54 : Colors.black54,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],

            // Profile Completeness & Missing Fields Banner
            if (!member.isProfileComplete)
              Container(
                margin: const EdgeInsets.only(bottom: 18),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: isDark ? 0.14 : 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.amber.withValues(alpha: 0.4),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.amber.shade800,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'INCOMPLETE PROFILE (${member.missingFields.length} LACKING)',
                            style: TextStyle(
                              color: Colors.amber.shade800,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This member record is lacking the following required details:',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: member.missingFields.map((field) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3.5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: isDark ? 0.2 : 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: Colors.amber.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.close_rounded,
                                size: 12,
                                color: Colors.amber.shade800,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                field,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? Colors.amber.shade200
                                      : Colors.amber.shade900,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              )
            else
              Container(
                margin: const EdgeInsets.only(bottom: 18),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: isDark ? 0.12 : 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.green.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: Colors.green,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Profile Complete - All required personal, ministry, and signature fields are verified.',
                        style: TextStyle(
                          color: isDark ? Colors.white70 : const Color(0xFF1B5E20),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Section 1: Ministry Positions & Leadership (Including Category)
            _buildSectionHeader('MINISTRY POSITIONS & LEADERSHIP', primaryColor),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildProfileRow(
                      context,
                      icon: Icons.groups_outlined,
                      label: 'Ministry Category',
                      value: member.dynamicCategory,
                    ),
                    if (member.positions.isNotEmpty) ...[
                      ...member.positions.map((pos) {
                        return Column(
                          children: [
                            const Divider(height: 20),
                            _buildProfileRow(
                              context,
                              icon: Icons.groups_outlined,
                              label: pos.level.isNotEmpty
                                  ? '${pos.level} Ministry'
                                  : 'Ministry Position',
                              value: pos.title,
                            ),
                          ],
                        );
                      }),
                    ] else ...[
                      const Divider(height: 20),
                      _buildProfileRow(
                        context,
                        icon: Icons.groups_outlined,
                        label: 'Assigned Position',
                        value: member.primaryRole,
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 18),

            // Section 2: Church & Affiliation
            StreamBuilder<TransferRequest?>(
              stream: FirestoreService().getPendingTransferStream(member.id),
              builder: (context, pendingSnapshot) {
                final pendingRequest = pendingSnapshot.data;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _buildSectionHeader('CHURCH & AFFILIATION', primaryColor),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Transfer History Button
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              icon: const Icon(Icons.history_rounded, size: 15),
                              label: const Text('History', style: TextStyle(fontSize: 12)),
                              onPressed: () => TransferHistorySheet.show(context, member),
                            ),
                            const SizedBox(width: 4),
                            // Request Transfer button or Pending badge
                            if (pendingRequest != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF9100).withValues(alpha: isDark ? 0.22 : 0.14),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFFFF9100).withValues(alpha: 0.5)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.hourglass_top_rounded, size: 13, color: Color(0xFFFF9100)),
                                    SizedBox(width: 4),
                                    Text(
                                      'Pending Transfer',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFFF9100),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                  foregroundColor: primaryColor,
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                                label: const Text(
                                  'Transfer Center',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                                onPressed: () async {
                                  final transferred = await Navigator.of(context).push<bool>(
                                    MaterialPageRoute(
                                      builder: (_) => TransferRequestScreen(member: member),
                                    ),
                                  );
                                  if (transferred == true) {
                                    _refreshMember();
                                  }
                                },
                              ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Pending Transfer Alert Banner if active
                    if (pendingRequest != null) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF9100).withValues(alpha: isDark ? 0.15 : 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFF9100).withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.pending_actions_rounded, color: Color(0xFFFF9100), size: 22),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Pending Transfer to ${pendingRequest.toCenter}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFFF9100),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Reason: "${pendingRequest.reason}" • Awaiting District Admin verification',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: isDark ? Colors.white70 : Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _buildProfileRow(
                              context,
                              icon: Icons.church_outlined,
                              label: 'Local Center / Branch',
                              value: member.center.isNotEmpty
                                  ? member.center
                                  : 'Antipolo Center',
                            ),
                            const Divider(height: 20),
                            _buildProfileRow(
                              context,
                              icon: Icons.map_outlined,
                              label: 'District & Area',
                              value: '${member.district} • ${member.area}',
                            ),
                            const Divider(height: 20),
                            _buildProfileRow(
                              context,
                              icon: Icons.calendar_today_outlined,
                              label: 'Date Joined',
                              value: member.formattedDateJoined,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 18),

            // Section 3: Personal Information
            _buildSectionHeader('PERSONAL INFORMATION', primaryColor),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildProfileRow(
                      context,
                      icon: Icons.cake_outlined,
                      label: 'Date of Birth (Age)',
                      value: member.formattedDobWithAge,
                    ),
                    const Divider(height: 20),
                    _buildProfileRow(
                      context,
                      icon: Icons.wc_outlined,
                      label: 'Gender',
                      value: member.gender,
                    ),
                    const Divider(height: 20),
                    _buildProfileRow(
                      context,
                      icon: Icons.favorite_border_rounded,
                      label: 'Civil Status',
                      value: member.civilStatus,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 18),

            // Section 4: Contact Information
            _buildSectionHeader('CONTACT INFORMATION', primaryColor),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildProfileRow(
                      context,
                      icon: Icons.phone_outlined,
                      label: 'Contact Number',
                      value: member.contactNo.isNotEmpty
                          ? member.contactNo
                          : 'Not provided',
                    ),
                    const Divider(height: 20),
                    _buildProfileRow(
                      context,
                      icon: Icons.email_outlined,
                      label: 'Email Address',
                      value: member.email.isNotEmpty
                          ? member.email
                          : 'Not provided',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 18),

            // Section 5: Address Details
            _buildSectionHeader('ADDRESS DETAILS', primaryColor),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildProfileRow(
                      context,
                      icon: Icons.signpost_outlined,
                      label: 'Street / Zone',
                      value: member.street.isNotEmpty
                          ? member.street
                          : 'Not provided',
                    ),
                    const Divider(height: 20),
                    _buildProfileRow(
                      context,
                      icon: Icons.location_city_outlined,
                      label: 'Barangay',
                      value: member.barangay.isNotEmpty
                          ? member.barangay
                          : 'Not provided',
                    ),
                    const Divider(height: 20),
                    _buildProfileRow(
                      context,
                      icon: Icons.apartment_outlined,
                      label: 'Municipality / City',
                      value: member.municipality.isNotEmpty
                          ? member.municipality
                          : 'Antipolo',
                    ),
                    const Divider(height: 20),
                    _buildProfileRow(
                      context,
                      icon: Icons.terrain_outlined,
                      label: 'Province',
                      value: member.province.isNotEmpty
                          ? member.province
                          : 'Rizal',
                    ),
                    const Divider(height: 20),
                    _buildProfileRow(
                      context,
                      icon: Icons.public_outlined,
                      label: 'Region',
                      value: member.region.isNotEmpty
                          ? member.region
                          : 'CALABARZON',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 18),

            // Section 6: Signature & Verification
            _buildSectionHeader('SIGNATURE & VERIFICATION', primaryColor),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Signature Status',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: member.signatureUrl.isNotEmpty
                                ? Colors.green.withValues(alpha: 0.15)
                                : (member.signatureDeclined
                                    ? Colors.red.withValues(alpha: 0.15)
                                    : Colors.amber.withValues(alpha: 0.15)),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            member.signatureUrl.isNotEmpty
                                ? 'SIGNED & VERIFIED'
                                : (member.signatureDeclined
                                    ? 'DECLINED'
                                    : 'NOT AVAILABLE'),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: member.signatureUrl.isNotEmpty
                                  ? Colors.green.shade700
                                  : (member.signatureDeclined
                                      ? Colors.red.shade700
                                      : Colors.amber.shade800),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (member.signatureUrl.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      InkWell(
                        onTap: () => _openImageViewer(
                          context,
                          title: member.fullName,
                          subtitle: 'Digital Signature',
                          imageUrl: member.signatureUrl,
                          isSignature: true,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          height: 90,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: primaryColor.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Stack(
                            children: [
                              Center(
                                child: member.signatureImageProvider != null
                                    ? Image(
                                        image: member.signatureImageProvider!,
                                        fit: BoxFit.contain,
                                        height: 75,
                                      )
                                    : const SizedBox.shrink(),
                              ),
                              Positioned(
                                right: 8,
                                bottom: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.65),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.zoom_in_rounded,
                                        size: 12,
                                        color: Colors.white,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'Tap to expand',
                                        style: TextStyle(
                                          fontSize: 9.5,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ] else if (!member.signatureDeclined) ...[
                      const SizedBox(height: 10),
                      Text(
                        'No digital signature registered on file.',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white54 : Colors.black54,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color primaryColor) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: primaryColor,
      ),
    );
  }

  Widget _buildProfileRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final textMuted = isDark ? Colors.white54 : Colors.black54;
    final textPrimary = isDark ? const Color(0xFFF5F5FA) : const Color(0xFF0E0E14);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: primaryColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: textMuted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
