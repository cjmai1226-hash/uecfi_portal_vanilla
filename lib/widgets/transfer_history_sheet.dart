import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/member.dart';
import '../models/transfer_request.dart';
import '../services/firestore_service.dart';

class TransferHistorySheet extends StatelessWidget {
  final Member member;

  const TransferHistorySheet({
    super.key,
    required this.member,
  });

  static void show(BuildContext context, Member member) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => TransferHistorySheet(member: member),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final textPrimary = isDark ? const Color(0xFFF5F5FA) : const Color(0xFF0E0E14);
    final textSecondary = isDark ? const Color(0xFF9E9EAF) : const Color(0xFF6E6E82);
    final cardBg = isDark ? const Color(0xFF1E1E2A) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2E2E3E) : const Color(0xFFE5E5ED);

    return SafeArea(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
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

            // Header Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.history_rounded, color: primaryColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Center Transfer History',
                        style: TextStyle(
                          fontSize: 17.5,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      Text(
                        member.fullName,
                        style: TextStyle(fontSize: 12.5, color: textSecondary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Expanded(
              child: StreamBuilder<List<TransferRequest>>(
                stream: FirestoreService().getMemberTransferHistoryStream(member.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final list = snapshot.data ?? [];

                  if (list.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.swap_horiz_rounded,
                              size: 44,
                              color: textSecondary.withValues(alpha: 0.4),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No transfer requests found for this member.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 14, color: textSecondary),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: list.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = list[index];
                      final dateStr = DateFormat('MMM dd, yyyy').format(item.requestedAt);

                      Color statusColor;
                      String statusText;
                      if (item.isPending) {
                        statusColor = const Color(0xFFFF9100);
                        statusText = 'PENDING VERIFICATION';
                      } else if (item.isApproved) {
                        statusColor = const Color(0xFF00C853);
                        statusText = 'TRANSFERRED / APPROVED';
                      } else {
                        statusColor = const Color(0xFFFF2A55);
                        statusText = 'DECLINED';
                      }

                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  dateStr,
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textSecondary),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: isDark ? 0.22 : 0.12),
                                    borderRadius: BorderRadius.circular(5),
                                    border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                                  ),
                                  child: Text(
                                    statusText,
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                      color: statusColor,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'From',
                                        style: TextStyle(fontSize: 10, color: textSecondary),
                                      ),
                                      Text(
                                        item.fromCenter,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: textPrimary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                                  child: Icon(Icons.arrow_forward_rounded, size: 16),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'To',
                                        style: TextStyle(fontSize: 10, color: Color(0xFF00B0FF)),
                                      ),
                                      Text(
                                        item.toCenter,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF00B0FF),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Reason: "${item.reason}"',
                              style: TextStyle(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                            if (item.reviewedByName != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                item.isApproved
                                    ? 'Approved by ${item.reviewedByName}'
                                    : 'Declined by ${item.reviewedByName}: ${item.reviewNotes ?? ""}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: item.isApproved ? Colors.green.shade700 : Colors.red.shade700,
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
