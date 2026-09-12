import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/center_model.dart';
import '../models/member.dart';
import '../models/transfer_request.dart';
import '../services/database_service.dart';
import '../services/firestore_service.dart';

class TransferRequestScreen extends StatefulWidget {
  final Member member;

  const TransferRequestScreen({
    super.key,
    required this.member,
  });

  @override
  State<TransferRequestScreen> createState() => _TransferRequestScreenState();
}

class _TransferRequestScreenState extends State<TransferRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _reasonController = TextEditingController();
  final DatabaseService _databaseService = DatabaseService();
  final FirestoreService _firestoreService = FirestoreService();

  List<CenterModel> _allCenters = [];
  CenterModel? _selectedTargetCenter;
  bool _isLoadingCenters = true;
  bool _isSubmitting = false;
  String? _selectedPresetReason;

  static const List<String> _presetReasons = [
    'Relocation / Moved Residence',
    'Employment / Work Transfer',
    'Family / Marriage',
    'Ministry Assignment',
    'Care & Fellowship Accessibility',
    'Personal / Other',
  ];

  @override
  void initState() {
    super.initState();
    _loadAvailableCenters();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableCenters() async {
    try {
      final centers = await _databaseService.getCenters();
      // Filter out the member's current center (case-insensitive)
      final currentCenterName = widget.member.center.trim().toLowerCase();
      final filtered = centers.where((c) {
        return c.centerName.trim().toLowerCase() != currentCenterName;
      }).toList();

      filtered.sort((a, b) => a.centerName.toLowerCase().compareTo(b.centerName.toLowerCase()));

      if (mounted) {
        setState(() {
          _allCenters = filtered;
          if (filtered.isNotEmpty) {
            _selectedTargetCenter = filtered.first;
          }
          _isLoadingCenters = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingCenters = false;
        });
      }
    }
  }

  Future<void> _submitTransferRequest() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTargetCenter == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a target local center to transfer to.'),
          backgroundColor: Color(0xFFFF2A55),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // 1. Check if member already has a pending transfer request
      final existingPending = await _firestoreService.getPendingTransferForMember(widget.member.id);
      if (existingPending != null) {
        if (mounted) {
          setState(() => _isSubmitting = false);
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Transfer Request Already Pending'),
              content: Text(
                'A pending transfer request to "${existingPending.toCenter}" is currently awaiting District Admin verification. Multiple pending requests are not allowed.',
              ),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
        return;
      }

      // 2. Resolve current requester details
      final currentUser = FirebaseAuth.instance.currentUser;
      final currentLoggedInMember = await _firestoreService.getCurrentMember();
      final requesterUid = currentUser?.uid ?? 'unknown';
      final requesterName = currentLoggedInMember?.fullName.isNotEmpty == true
          ? currentLoggedInMember!.fullName
          : (currentUser?.displayName ?? currentUser?.email?.split('@').first ?? 'Portal User');

      // 3. Construct request
      final request = TransferRequest(
        id: '',
        memberDocId: widget.member.id,
        memberId: widget.member.memberId,
        memberName: widget.member.fullName,
        fromCenter: widget.member.center.isNotEmpty ? widget.member.center : 'Unassigned',
        fromArea: widget.member.area.isNotEmpty ? widget.member.area : 'Area 1',
        fromDistrict: widget.member.district.isNotEmpty ? widget.member.district : 'District 3',
        toCenter: _selectedTargetCenter!.centerName,
        toArea: _selectedTargetCenter!.area.isNotEmpty ? _selectedTargetCenter!.area : 'Area 1',
        toDistrict: _selectedTargetCenter!.district.isNotEmpty
            ? _selectedTargetCenter!.district
            : 'District 3',
        reason: _reasonController.text.trim(),
        status: 'pending',
        requestedByUid: requesterUid,
        requestedByName: requesterName,
        requestedAt: DateTime.now(),
      );

      await _firestoreService.createTransferRequest(request);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Transfer request for ${widget.member.fullName} has been sent to District Admins.',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF00C853),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 4),
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit transfer request: $e'),
            backgroundColor: const Color(0xFFFF2A55),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final textPrimary = isDark ? const Color(0xFFF5F5FA) : const Color(0xFF0E0E14);
    final textSecondary = isDark ? const Color(0xFF9E9EAF) : const Color(0xFF6E6E82);
    final cardBg = isDark ? const Color(0xFF16161F) : Colors.white;
    final borderColor = isDark ? const Color(0xFF262633) : const Color(0xFFE5E5ED);

    final currentCenter = widget.member.center.isNotEmpty
        ? widget.member.center
        : 'Unassigned Center';
    final currentArea = widget.member.area.isNotEmpty ? widget.member.area : 'Area 1';
    final currentDistrict = widget.member.district.isNotEmpty
        ? widget.member.district
        : 'District 3';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Request Local Center Transfer',
          style: TextStyle(
            color: textPrimary,
            fontSize: 18,
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
      body: _isLoadingCenters
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                children: [
                  // Member Identity Header Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor, width: 1.1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: primaryColor.withValues(alpha: 0.15),
                          backgroundImage: widget.member.profileImageProvider,
                          child: widget.member.profileUrl.isEmpty
                              ? Text(
                                  widget.member.initials,
                                  style: TextStyle(
                                    color: primaryColor,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.member.fullName,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'ID: ${widget.member.memberId} • ${widget.member.primaryRole}',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Route Overview: From Center -> To Center
                  _buildSectionHeader('CHURCH AFFILIATION TRANSFER ROUTE', primaryColor),
                  const SizedBox(height: 8),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor, width: 1.1),
                    ),
                    child: Column(
                      children: [
                        // Current Center Row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.church_outlined, size: 18, color: Colors.grey),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'CURRENT AFFILIATION (ORIGIN)',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.8,
                                      color: textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    currentCenter,
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.bold,
                                      color: textPrimary,
                                    ),
                                  ),
                                  Text(
                                    '$currentDistrict • $currentArea',
                                    style: TextStyle(fontSize: 12, color: textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
                          child: Row(
                            children: [
                              Container(
                                width: 2,
                                height: 24,
                                color: primaryColor.withValues(alpha: 0.4),
                              ),
                              const SizedBox(width: 12),
                              Icon(Icons.arrow_downward_rounded, size: 16, color: primaryColor),
                              const SizedBox(width: 6),
                              Text(
                                'Transferring to',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Destination Target Center Dropdown
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: primaryColor.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.add_location_alt_outlined, size: 18, color: primaryColor),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'DESTINATION AFFILIATION (TARGET) *',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.8,
                                      color: primaryColor,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  DropdownButtonFormField<CenterModel>(
                                    initialValue: _selectedTargetCenter,
                                    isExpanded: true,
                                    decoration: InputDecoration(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: borderColor),
                                      ),
                                    ),
                                    items: _allCenters.map((center) {
                                      return DropdownMenuItem<CenterModel>(
                                        value: center,
                                        child: Text(
                                          center.displayNameWithAddress,
                                          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      setState(() {
                                        _selectedTargetCenter = val;
                                      });
                                    },
                                    validator: (val) => val == null ? 'Please select a destination center' : null,
                                  ),
                                  if (_selectedTargetCenter != null) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      '${_selectedTargetCenter!.district} • ${_selectedTargetCenter!.area}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: primaryColor,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Reason & Justification Section
                  _buildSectionHeader('REASON FOR TRANSFER REQUEST *', primaryColor),
                  const SizedBox(height: 8),

                  // Preset Reason Chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _presetReasons.map((preset) {
                      final isSelected = _selectedPresetReason == preset;
                      return ChoiceChip(
                        label: Text(
                          preset,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: primaryColor,
                        backgroundColor: cardBg,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: isSelected ? primaryColor : borderColor),
                        ),
                        showCheckmark: false,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedPresetReason = preset;
                              if (_reasonController.text.trim().isEmpty) {
                                _reasonController.text = preset;
                              }
                            } else {
                              _selectedPresetReason = null;
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 12),

                  // Detailed Reason Text Field
                  TextFormField(
                    controller: _reasonController,
                    maxLines: 4,
                    minLines: 3,
                    style: const TextStyle(fontSize: 13.5),
                    decoration: InputDecoration(
                      hintText: 'State the specific reason or circumstance for the requested local center transfer...',
                      contentPadding: const EdgeInsets.all(14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: borderColor),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Please provide a reason for the transfer request.';
                      }
                      if (val.trim().length < 5) {
                        return 'Please enter at least 5 characters.';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Administrative Verification Notice Box
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00B0FF).withValues(alpha: isDark ? 0.14 : 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF00B0FF).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          size: 20,
                          color: Color(0xFF00B0FF),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Transfer requests are submitted as "Pending" and routed directly to the District Administrator. Once verified and accepted, the member\'s official center and jurisdiction will automatically be updated.',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white70 : const Color(0xFF01579B),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Submit Button
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitTransferRequest,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.send_rounded, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'Submit Transfer Request',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title, Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.only(left: 2.0),
      child: Text(
        title,
        style: TextStyle(
          color: primaryColor,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}
