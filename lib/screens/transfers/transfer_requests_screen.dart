import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/member.dart';
import '../../models/transfer_request.dart';
import '../../services/firestore_service.dart';

class TransferRequestsScreen extends StatefulWidget {
  const TransferRequestsScreen({super.key});

  @override
  State<TransferRequestsScreen> createState() => _TransferRequestsScreenState();
}

class _TransferRequestsScreenState extends State<TransferRequestsScreen>
    with SingleTickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _showReviewDialog(BuildContext context, TransferRequest request) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final textPrimary = isDark ? const Color(0xFFF5F5FA) : const Color(0xFF0E0E14);
    final textSecondary = isDark ? const Color(0xFF9E9EAF) : const Color(0xFF6E6E82);
    final cardBg = isDark ? const Color(0xFF1E1E2A) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2E2E3E) : const Color(0xFFE5E5ED);

    final requestedDateStr = DateFormat('MMMM dd, yyyy • hh:mm a').format(request.requestedAt);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 16,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
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
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.swap_horiz_rounded, color: primaryColor, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Review Center Transfer',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                            ),
                            Text(
                              'District Administration Verification',
                              style: TextStyle(fontSize: 12, color: textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Member Identity Box
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF262633) : const Color(0xFFF7F7FA),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.person_outline_rounded, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                request.memberName,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: textPrimary,
                                ),
                              ),
                              Text(
                                'Member ID: ${request.memberId}',
                                style: TextStyle(fontSize: 12, color: textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Transfer Route Box
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF16161F) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ORIGIN CENTER',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          request.fromCenter,
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textPrimary),
                        ),
                        if (request.fromCenterAddress.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(Icons.location_on_outlined, size: 12, color: textSecondary),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  request.fromCenterAddress,
                                  style: TextStyle(fontSize: 11.5, color: textSecondary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                        Text(
                          '${request.fromDistrict} • ${request.fromArea}',
                          style: TextStyle(fontSize: 12, color: textSecondary),
                        ),
                        const Divider(height: 20),
                        Text(
                          'NEW TARGET CENTER (PROPOSED)',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: const Color(0xFF00B0FF),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          request.toCenter,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF00B0FF),
                          ),
                        ),
                        if (request.toCenterAddress.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined, size: 12, color: Color(0xFF00B0FF)),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  request.toCenterAddress,
                                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF00B0FF)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                        Text(
                          '${request.toDistrict} • ${request.toArea}',
                          style: TextStyle(fontSize: 12, color: textSecondary),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Reason Box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF16161F) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'STATED REASON FOR TRANSFER',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          request.reason,
                          style: TextStyle(fontSize: 13.5, height: 1.4, color: textPrimary),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Requested by ${request.requestedByName} on $requestedDateStr',
                          style: TextStyle(fontSize: 11, color: textSecondary),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  // Action Buttons (Approve / Reject)
                  if (request.isPending) ...[
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFFF2A55),
                              side: const BorderSide(color: Color(0xFFFF2A55), width: 1.2),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () {
                              Navigator.of(ctx).pop();
                              _showRejectConfirmation(context, request);
                            },
                            child: const Text('Decline Transfer'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00C853),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () {
                              Navigator.of(ctx).pop();
                              _showApproveConfirmation(context, request);
                            },
                            child: const Text('Accept Transfer'),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: request.isApproved
                              ? Colors.green.withValues(alpha: 0.15)
                              : Colors.red.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          request.isApproved
                              ? 'Transfer Approved by ${request.reviewedByName ?? "Admin"}'
                              : 'Transfer Declined: ${request.reviewNotes ?? "No reason given"}',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: request.isApproved ? Colors.green.shade700 : Colors.red.shade700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showApproveConfirmation(BuildContext context, TransferRequest request) {
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Accept Member Transfer?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Accepting will officially transfer "${request.memberName}" to "${request.toCenter}" (${request.toDistrict} • ${request.toArea}) and update their church affiliation in the district roster.',
            ),
            const SizedBox(height: 14),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Approval Remarks (Optional)',
                hintText: 'e.g. Endorsed by District Pastor',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00C853),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await _firestoreService.approveTransferRequest(
                  request: request,
                  notes: notesController.text.trim().isNotEmpty ? notesController.text.trim() : null,
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${request.memberName} was successfully transferred to ${request.toCenter}!'),
                      backgroundColor: const Color(0xFF00C853),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to approve transfer: $e'),
                      backgroundColor: const Color(0xFFFF2A55),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: const Text('Confirm & Transfer'),
          ),
        ],
      ),
    );
  }

  void _showRejectConfirmation(BuildContext context, TransferRequest request) {
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Decline Transfer Request'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Please provide a reason for declining ${request.memberName}\'s transfer request to ${request.toCenter}:',
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: reasonController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Reason for Declining *',
                  hintText: 'e.g. Lack of local clearance or incorrect center selected',
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
              ),
            ],
          ),
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
            ),
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              Navigator.of(ctx).pop();
              try {
                await _firestoreService.rejectTransferRequest(
                  request: request,
                  notes: reasonController.text.trim(),
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Transfer request for ${request.memberName} was declined.'),
                      backgroundColor: const Color(0xFFFF2A55),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to decline transfer: $e'),
                      backgroundColor: const Color(0xFFFF2A55),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: const Text('Decline Request'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? const Color(0xFFF5F5FA) : const Color(0xFF0E0E14);
    final textSecondary = isDark ? const Color(0xFF9E9EAF) : const Color(0xFF6E6E82);

    return StreamBuilder<Member?>(
      stream: _firestoreService.getCurrentMemberStream(),
      builder: (context, memberSnapshot) {
        final currentMember = memberSnapshot.data;
        final hasAccess = currentMember != null &&
            (currentMember.isAdmin || currentMember.isDistrictLeader);

        if (memberSnapshot.hasData && !hasAccess) {
          return Scaffold(
            appBar: AppBar(title: const Text('Transfer Requests')),
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
                      'Local center transfer requests can only be managed by Administrators and District Admins.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: textSecondary, height: 1.4),
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

        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Local Center Transfers',
              style: TextStyle(
                color: textPrimary,
                fontSize: 19,
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
            bottom: TabBar(
              controller: _tabController,
              tabs: [
                StreamBuilder<int>(
                  stream: _firestoreService.getPendingTransfersCountStream(),
                  builder: (context, countSnapshot) {
                    final pendingCount = countSnapshot.data ?? 0;
                    return Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Pending Requests'),
                          if (pendingCount > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF9100),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$pendingCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
                const Tab(text: 'Transfer History'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              // Tab 1: Pending Requests
              _buildRequestsList(status: 'pending', isPendingTab: true),
              // Tab 2: History (Approved & Rejected)
              _buildRequestsList(status: null, isPendingTab: false),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRequestsList({required String? status, required bool isPendingTab}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark ? const Color(0xFF9E9EAF) : const Color(0xFF6E6E82);

    return StreamBuilder<List<TransferRequest>>(
      stream: _firestoreService.getTransferRequestsStream(status: status),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final allRequests = snapshot.data ?? [];
        // For history tab, filter out pending
        final requests = isPendingTab
            ? allRequests.where((r) => r.isPending).toList()
            : allRequests.where((r) => !r.isPending).toList();

        if (requests.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isPendingTab ? Icons.check_circle_outline_rounded : Icons.history_rounded,
                  size: 48,
                  color: textSecondary.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 12),
                Text(
                  isPendingTab
                      ? 'No pending transfer requests.'
                      : 'No transfer history recorded yet.',
                  style: TextStyle(
                    fontSize: 15,
                    color: textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          itemCount: requests.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final req = requests[index];
            return _buildTransferCard(req);
          },
        );
      },
    );
  }

  Widget _buildTransferCard(TransferRequest request) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? const Color(0xFFF5F5FA) : const Color(0xFF0E0E14);
    final textSecondary = isDark ? const Color(0xFF9E9EAF) : const Color(0xFF6E6E82);
    final cardBg = isDark ? const Color(0xFF16161F) : Colors.white;
    final borderColor = isDark ? const Color(0xFF262633) : const Color(0xFFE5E5ED);

    Color statusColor;
    String statusLabel;
    if (request.isPending) {
      statusColor = const Color(0xFFFF9100);
      statusLabel = 'PENDING';
    } else if (request.isApproved) {
      statusColor = const Color(0xFF00C853);
      statusLabel = 'APPROVED';
    } else {
      statusColor = const Color(0xFFFF2A55);
      statusLabel = 'DECLINED';
    }

    final dateStr = DateFormat('MMM dd, yyyy').format(request.requestedAt);

    return Card(
      color: cardBg,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: borderColor),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _showReviewDialog(context, request),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Member Name + Status Badge
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.memberName,
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'ID: ${request.memberId}',
                          style: TextStyle(fontSize: 11.5, color: textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: isDark ? 0.22 : 0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Route representation
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E2A) : const Color(0xFFF7F7FA),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'FROM',
                            style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: textSecondary),
                          ),
                          Text(
                            request.fromCenter,
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (request.fromCenterAddress.isNotEmpty)
                            Text(
                              request.fromCenterAddress,
                              style: TextStyle(fontSize: 10.5, color: textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Icon(Icons.arrow_forward_rounded, size: 18, color: textSecondary),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'TO',
                            style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF00B0FF)),
                          ),
                          Text(
                            request.toCenter,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF00B0FF),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (request.toCenterAddress.isNotEmpty)
                            Text(
                              request.toCenterAddress,
                              style: const TextStyle(fontSize: 10.5, color: Color(0xFF00B0FF)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // Reason
              Text(
                'Reason: "${request.reason}"',
                style: TextStyle(
                  fontSize: 12.5,
                  fontStyle: FontStyle.italic,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 8),

              // Date + Tap to review hint
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Requested $dateStr',
                    style: TextStyle(fontSize: 11, color: textSecondary),
                  ),
                  Row(
                    children: [
                      Text(
                        request.isPending ? 'Review & Verify' : 'View Details',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
