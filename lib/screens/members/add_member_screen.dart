import 'dart:convert';
import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:philippines_rpcmb/philippines_rpcmb.dart';
import '../../models/center_model.dart';
import '../../models/member.dart';
import '../../services/database_service.dart';
import '../../services/firestore_service.dart';
import '../../utils/date_formatter.dart';
import '../../utils/image_utils.dart';
import '../../widgets/image_crop_screen.dart';
import '../../widgets/signature_pad.dart';

class PositionFormItem {
  String level;
  final TextEditingController controller;

  PositionFormItem({this.level = 'Local', String initialPosition = 'Member'})
    : controller = TextEditingController(text: initialPosition);

  void dispose() {
    controller.dispose();
  }
}

class AddMemberScreen extends StatefulWidget {
  final Member? memberToEdit;

  const AddMemberScreen({super.key, this.memberToEdit});

  @override
  State<AddMemberScreen> createState() => _AddMemberScreenState();
}

class _AddMemberScreenState extends State<AddMemberScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirestoreService _firestoreService = FirestoreService();
  final DatabaseService _databaseService = DatabaseService();

  // Text Controllers
  final TextEditingController _memberIdController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _middleNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _contactNoController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _streetController = TextEditingController();

  final List<PositionFormItem> _positionItems = [
    PositionFormItem(level: 'Local', initialPosition: 'Member'),
  ];

  // 1x1 Profile Photo
  Uint8List? _profileImageBytes;
  String _profileBase64 = '';

  // Digital Signature
  Uint8List? _signatureBytes;
  String _signatureBase64 = '';
  bool _signatureDeclined = false;

  // Jurisdiction Selections
  String _selectedDistrict = 'District 3';
  String _selectedArea = 'Area 1';
  String _selectedCenter = '';

  // Demographics
  String _gender = 'Male';
  String _civilStatus = 'Single';
  String _membershipStatus = 'Active';
  bool get _isInactive => _membershipStatus.trim().toLowerCase() == 'inactive';
  String _inactiveReason = 'Relocated / Moved Residence';
  String _memberType = 'Regular';

  static const List<String> _inactiveReasons = [
    'Relocated / Moved Residence',
    'Transferred to Another Church',
    'Work / Schedule Conflict',
    'Health / Medical Reasons',
    'Family Concerns',
    'Deceased',
    'Prolonged Absence / Uncontactable',
    'Personal Decision',
    'Other',
  ];

  // Philippine Address
  Region? _selectedRegion;
  Province? _selectedProvince;
  Municipality? _selectedMunicipality;
  String? _selectedBarangay;

  DateTime? _selectedDob;
  DateTime _selectedDateJoined = DateTime.now();
  List<CenterModel> _allCenters = [];
  List<Member> _allExistingMembers = [];
  Member? _currentUser;
  bool _isLoading = false;

  void _onNameFieldChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  List<Member> get _nameDuplicates {
    final f = Member.normalizeName(_firstNameController.text);
    final m = Member.normalizeName(_middleNameController.text);
    final l = Member.normalizeName(_lastNameController.text);
    if (f.isEmpty || l.isEmpty) return [];

    return _allExistingMembers.where((other) {
      if (widget.memberToEdit != null) {
        if (other.memberId == widget.memberToEdit!.memberId) return false;
        if (other.id.isNotEmpty &&
            widget.memberToEdit!.id.isNotEmpty &&
            other.id == widget.memberToEdit!.id) {
          return false;
        }
      }
      final of = Member.normalizeName(other.firstName);
      final om = Member.normalizeName(other.middleName);
      final ol = Member.normalizeName(other.lastName);
      return f == of && m == om && l == ol;
    }).toList();
  }

  bool get _hasProfilePhoto =>
      _profileImageBytes != null ||
      (_profileBase64.trim().isNotEmpty && _profileBase64.trim() != 'N/A');

  ImageProvider? get _currentProfileImageProvider {
    if (_profileImageBytes != null) {
      return MemoryImage(_profileImageBytes!);
    }
    final url = _profileBase64.trim();
    if (url.isEmpty || url == 'N/A') return null;
    if (url.startsWith('data:image') || !url.startsWith('http')) {
      try {
        final raw = url.contains(',') ? url.split(',').last : url;
        return MemoryImage(base64Decode(raw));
      } catch (_) {
        return null;
      }
    }
    return CachedNetworkImageProvider(url);
  }

  bool get _hasSignature =>
      _signatureBytes != null ||
      (_signatureBase64.trim().isNotEmpty && _signatureBase64.trim() != 'N/A');

  ImageProvider? get _currentSignatureImageProvider {
    if (_signatureBytes != null) {
      return MemoryImage(_signatureBytes!);
    }
    final url = _signatureBase64.trim();
    if (url.isEmpty || url == 'N/A') return null;
    if (url.startsWith('data:image') || !url.startsWith('http')) {
      try {
        final raw = url.contains(',') ? url.split(',').last : url;
        return MemoryImage(base64Decode(raw));
      } catch (_) {
        return null;
      }
    }
    return CachedNetworkImageProvider(url);
  }

  String get _dynamicCategory {
    final age = _selectedDob != null
        ? DateTime.now().year - _selectedDob!.year
        : 30;
    return Member.calculateCategory(age: age, civilStatus: _civilStatus);
  }

  @override
  void initState() {
    super.initState();
    _loadCenters();

    _firstNameController.addListener(_onNameFieldChanged);
    _middleNameController.addListener(_onNameFieldChanged);
    _lastNameController.addListener(_onNameFieldChanged);

    _firestoreService
        .getCurrentMember()
        .then((user) {
          if (mounted && user != null) {
            setState(() {
              _currentUser = user;
              if (widget.memberToEdit == null) {
                if (user.isDistrictLocked && user.district.isNotEmpty) {
                  _selectedDistrict = user.district;
                }
                if (user.isAreaLocked && user.area.isNotEmpty) {
                  _selectedArea = user.area;
                }
                if (user.isCenterLocked && user.center.isNotEmpty) {
                  _selectedCenter = user.center;
                }
              }
            });
          }
        })
        .catchError((_) {});

    _firestoreService
        .getMembersOnce()
        .then((list) {
          if (mounted) {
            setState(() {
              _allExistingMembers = list;
              if (widget.memberToEdit == null) {
                _memberIdController.text = Member.generateNextMemberId(list);
              }
            });
          }
        })
        .catchError((_) {});

    if (widget.memberToEdit != null) {
      final m = widget.memberToEdit!;
      _populateAddressForMember(m);
      _memberIdController.text = m.memberId;
      _firstNameController.text = m.firstName;
      _middleNameController.text = m.middleName;
      _lastNameController.text = m.lastName;

      // Cleanly parse & format DOB as yyyy-MM-dd (never showing raw ISO strings like 2009-07-12T00:00:00.000z)
      final parsedDob = DateFormatter.parseDate(m.dob);
      if (parsedDob != null) {
        _selectedDob = parsedDob;
        _dobController.text = DateFormat('yyyy-MM-dd').format(parsedDob);
      } else if (m.dob.contains('T') || m.dob.contains('t')) {
        _dobController.text = m.dob.split(RegExp(r'[Tt]')).first.trim();
      } else {
        _dobController.text = m.dob;
      }

      _contactNoController.text = m.contactNo;
      _emailController.text = m.email;
      _streetController.text = m.street;
      _gender = m.gender;
      _civilStatus = m.civilStatus;
      _membershipStatus = m.membershipStatus;
      if (m.inactiveReason.isNotEmpty) {
        _inactiveReason = m.inactiveReason;
      }
      _memberType = m.memberType;
      if (m.district.isNotEmpty) _selectedDistrict = m.district;
      if (m.area.isNotEmpty) _selectedArea = m.area;
      if (m.center.isNotEmpty) _selectedCenter = m.center;

      if (m.dateJoined.isNotEmpty) {
        final parsedJoined = DateFormatter.parseDate(m.dateJoined);
        if (parsedJoined != null) {
          _selectedDateJoined = parsedJoined;
        }
      }

      _profileBase64 = m.profileUrl;
      if (_profileBase64.isNotEmpty && !_profileBase64.startsWith('http')) {
        try {
          final raw = _profileBase64.contains(',')
              ? _profileBase64.split(',').last
              : _profileBase64;
          _profileImageBytes = base64Decode(raw);
        } catch (_) {}
      }

      _signatureBase64 = m.signatureUrl;
      if (_signatureBase64.isNotEmpty && !_signatureBase64.startsWith('http')) {
        try {
          final raw = _signatureBase64.contains(',')
              ? _signatureBase64.split(',').last
              : _signatureBase64;
          _signatureBytes = base64Decode(raw);
        } catch (_) {}
      }
      _signatureDeclined = m.signatureDeclined;

      if (m.positions.isNotEmpty) {
        _positionItems.clear();
        for (final p in m.positions) {
          _positionItems.add(
            PositionFormItem(level: p.level, initialPosition: p.position),
          );
        }
      }
    } else {
      _initializePhilippineAddress();
      _memberIdController.text = Member.generateNextMemberId(
        _allExistingMembers,
      );
    }
  }

  @override
  void dispose() {
    _firstNameController.removeListener(_onNameFieldChanged);
    _middleNameController.removeListener(_onNameFieldChanged);
    _lastNameController.removeListener(_onNameFieldChanged);
    _memberIdController.dispose();
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _dobController.dispose();
    _contactNoController.dispose();
    _emailController.dispose();
    _streetController.dispose();
    for (final item in _positionItems) {
      item.dispose();
    }
    super.dispose();
  }

  Future<void> _loadCenters() async {
    final centers = await _databaseService.getCenters();
    if (mounted) {
      setState(() {
        _allCenters = centers;
        if (_selectedCenter.isEmpty && centers.isNotEmpty) {
          if (_currentUser != null &&
              _currentUser!.isCenterLocked &&
              _currentUser!.center.isNotEmpty) {
            _selectedCenter = _currentUser!.center;
          } else {
            _selectedCenter = centers.first.centerName;
          }
        }
      });
    }
  }

  void _initializePhilippineAddress() {
    if (philippineRegions.isNotEmpty) {
      _selectedRegion = philippineRegions.firstWhere(
        (r) =>
            r.regionName.toUpperCase().contains('CALABARZON') ||
            r.regionName.toUpperCase().contains('IV-A'),
        orElse: () => philippineRegions.first,
      );

      if (_selectedRegion != null && _selectedRegion!.provinces.isNotEmpty) {
        _selectedProvince = _selectedRegion!.provinces.firstWhere(
          (p) => p.name.toUpperCase().contains('RIZAL'),
          orElse: () => _selectedRegion!.provinces.first,
        );

        if (_selectedProvince != null &&
            _selectedProvince!.municipalities.isNotEmpty) {
          _selectedMunicipality = _selectedProvince!.municipalities.firstWhere(
            (m) => m.name.toUpperCase().contains('ANTIPOLO'),
            orElse: () => _selectedProvince!.municipalities.first,
          );

          if (_selectedMunicipality != null &&
              _selectedMunicipality!.barangays.isNotEmpty) {
            _selectedBarangay = _selectedMunicipality!.barangays.first;
          }
        }
      }
    }
  }

  void _populateAddressForMember(Member m) {
    if (philippineRegions.isEmpty) return;

    final pSearch = m.province.trim().toLowerCase();
    final mSearch = m.municipality.trim().toLowerCase();
    final bSearch = m.barangay.trim().toLowerCase();

    Region? matchedRegion;

    if (pSearch.isNotEmpty) {
      for (final r in philippineRegions) {
        for (final p in r.provinces) {
          final pName = p.name.toLowerCase();
          if (pName == pSearch || pName.contains(pSearch)) {
            matchedRegion = r;
            break;
          }
        }
        if (matchedRegion != null) break;
      }
    }

    if (matchedRegion != null) {
      _selectedRegion = matchedRegion;
      for (final p in matchedRegion.provinces) {
        if (p.name.toLowerCase() == pSearch ||
            p.name.toLowerCase().contains(pSearch)) {
          _selectedProvince = p;
          for (final mun in p.municipalities) {
            if (mun.name.toLowerCase() == mSearch ||
                mun.name.toLowerCase().contains(mSearch)) {
              _selectedMunicipality = mun;
              for (final bar in mun.barangays) {
                if (bar.toLowerCase() == bSearch ||
                    bar.toLowerCase().contains(bSearch)) {
                  _selectedBarangay = bar;
                  break;
                }
              }
              break;
            }
          }
          break;
        }
      }
    }
  }

  Future<void> _pickProfileImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 90,
      );
      if (picked != null) {
        final rawBytes = await picked.readAsBytes();
        if (!mounted) return;

        // Downscale raw image if overly large to prevent memory/lag in cropper
        final inputBytes = await ImageUtils.prepareForCropping(rawBytes);
        if (!mounted) return;

        final croppedBytes = await ImageCropScreen.open(
          context,
          imageBytes: inputBytes,
          title: 'Crop Profile Photo (1x1)',
          aspectRatio: 1.0,
          lockAspectRatio: true,
        );

        if (croppedBytes != null) {
          // Compress into optimized 512x512 JPEG (~30-60 KB)
          final optimizedBytes =
              await ImageUtils.compressProfilePhoto(croppedBytes);
          if (!mounted) return;

          setState(() {
            _profileImageBytes = optimizedBytes;
            _profileBase64 =
                ImageUtils.toDataUrl(optimizedBytes, mimeType: 'image/jpeg');
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to select photo: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _showImageSourceModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '1x1 Profile Photo',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Upload and crop a square 1x1 formal ID photo for church membership record',
                  style: TextStyle(fontSize: 12.5, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.camera_alt_rounded),
                  title: const Text('Take Photo from Camera'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickProfileImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_rounded),
                  title: const Text('Choose from Gallery'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickProfileImage(ImageSource.gallery);
                  },
                ),
                if (_hasProfilePhoto)
                  ListTile(
                    leading: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.redAccent,
                    ),
                    title: const Text(
                      'Remove Photo',
                      style: TextStyle(color: Colors.redAccent),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      setState(() {
                        _profileImageBytes = null;
                        _profileBase64 = '';
                      });
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickSignatureImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 95,
      );
      if (picked != null) {
        final rawBytes = await picked.readAsBytes();
        if (!mounted) return;

        final inputBytes = await ImageUtils.prepareForCropping(rawBytes);
        if (!mounted) return;

        final croppedBytes = await ImageCropScreen.open(
          context,
          imageBytes: inputBytes,
          title: 'Crop Signature',
          aspectRatio: 3.0,
          lockAspectRatio: false,
        );

        if (croppedBytes != null && mounted) {
          final optimizedBytes =
              await ImageUtils.compressSignature(croppedBytes);
          if (!mounted) return;

          setState(() {
            _signatureBytes = optimizedBytes;
            _signatureBase64 =
                ImageUtils.toDataUrl(optimizedBytes, mimeType: 'image/png');
            _signatureDeclined = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to select signature image: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _showSignatureSourceModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Digital Signature',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Choose how you want to provide the member signature',
                  style: TextStyle(fontSize: 12.5, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.draw_rounded),
                  title: const Text('Draw on Fullscreen Canvas'),
                  subtitle: const Text('Landscape signing pad using finger or stylus'),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final bytes = await FullscreenSignatureScreen.open(
                      context,
                      initialSignatureBytes: _signatureBytes,
                    );
                    if (bytes != null && mounted) {
                      final optimized =
                          await ImageUtils.compressSignature(bytes);
                      if (!mounted) return;
                      setState(() {
                        _signatureBytes = optimized;
                        _signatureBase64 =
                            ImageUtils.toDataUrl(optimized, mimeType: 'image/png');
                        _signatureDeclined = false;
                      });
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_rounded),
                  title: const Text('Upload Photo from Gallery'),
                  subtitle: const Text('Select existing photo or image of signature'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickSignatureImage(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt_rounded),
                  title: const Text('Take Photo of Signature Paper'),
                  subtitle: const Text('Capture signature from paper with camera'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickSignatureImage(ImageSource.camera);
                  },
                ),
                if (_hasSignature)
                  ListTile(
                    leading: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.redAccent,
                    ),
                    title: const Text(
                      'Clear Signature',
                      style: TextStyle(color: Colors.redAccent),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      setState(() {
                        _signatureBytes = null;
                        _signatureBase64 = '';
                      });
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _selectDob(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDob ?? DateTime(now.year - 25, 1, 1),
      firstDate: DateTime(1920),
      lastDate: now,
    );

    if (picked != null) {
      setState(() {
        _selectedDob = picked;
        _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _submitForm() async {
    if (_isInactive) {
      if (_inactiveReason.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a reason for being inactive.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.amber,
          ),
        );
        return;
      }
    } else {
      if (!_formKey.currentState!.validate()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please complete all required fields.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.amber,
          ),
        );
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final nowStr = DateTime.now().toIso8601String();

      // Guard against any oversized legacy Base64 string before saving
      String safeProfileUrl = _profileBase64.trim();
      if (safeProfileUrl.startsWith('data:image') &&
          ImageUtils.estimateBase64SizeBytes(safeProfileUrl) >
              ImageUtils.maxPhotoBytes) {
        try {
          final raw = safeProfileUrl.contains(',')
              ? safeProfileUrl.split(',').last
              : safeProfileUrl;
          final decoded = base64Decode(raw);
          final recompressed =
              await ImageUtils.compressProfilePhoto(decoded);
          safeProfileUrl =
              ImageUtils.toDataUrl(recompressed, mimeType: 'image/jpeg');
        } catch (_) {}
      }

      if (widget.memberToEdit != null) {
        final updatedMember = widget.memberToEdit!.copyWith(
          memberId: _memberIdController.text.trim(),
          firstName: _firstNameController.text.trim(),
          middleName: _middleNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          dob: _dobController.text.trim(),
          gender: _gender,
          civilStatus: _civilStatus,
          category: _dynamicCategory,
          email: _emailController.text.trim().toLowerCase(),
          contactNo: _contactNoController.text.trim(),
          region: _selectedRegion?.regionName ?? widget.memberToEdit!.region,
          province: _selectedProvince?.name ?? widget.memberToEdit!.province,
          municipality:
              _selectedMunicipality?.name ?? widget.memberToEdit!.municipality,
          barangay: _selectedBarangay ?? widget.memberToEdit!.barangay,
          street: _streetController.text.trim(),
          district: _selectedDistrict,
          area: _selectedArea,
          center: _selectedCenter,
          positions: _positionItems
              .where((item) => item.controller.text.trim().isNotEmpty)
              .map(
                (item) => MemberPosition(
                  level: item.level,
                  position: item.controller.text.trim(),
                ),
              )
              .toList(),
          status: _isInactive
              ? 'inactive'
              : (widget.memberToEdit?.status == 'inactive'
                  ? 'registered'
                  : (widget.memberToEdit?.status ?? 'registered')),
          membershipStatus: _membershipStatus,
          inactiveReason: _isInactive ? _inactiveReason.trim() : '',
          memberType: _memberType,
          dateJoined: DateFormat('yyyy-MM-dd').format(_selectedDateJoined),
          profileUrl: safeProfileUrl,
          signatureUrl: _signatureDeclined ? '' : _signatureBase64,
          signatureDeclined: _signatureDeclined,
          updatedAt: nowStr,
        );

        await _firestoreService.updateMember(
          updatedMember,
          originalMember: widget.memberToEdit,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.white),
                  const SizedBox(width: 10),
                  Text('Member ${updatedMember.fullName} updated!'),
                ],
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(updatedMember);
        }
        return;
      }

      // Add New Member
      final assignedMemberId = _memberIdController.text.trim().isNotEmpty
          ? _memberIdController.text.trim()
          : Member.generateNextMemberId(_allExistingMembers);

      final newMember = Member(
        id: '',
        memberId: assignedMemberId,
        uid: '',
        role: 'member',
        status: _isInactive ? 'inactive' : 'registered',
        firstName: _firstNameController.text.trim(),
        middleName: _middleNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        dob: _dobController.text.trim(),
        gender: _gender,
        civilStatus: _civilStatus,
        category: _dynamicCategory,
        email: _emailController.text.trim().toLowerCase(),
        contactNo: _contactNoController.text.trim(),
        region: _selectedRegion?.regionName ?? 'CALABARZON',
        province: _selectedProvince?.name ?? 'Rizal',
        municipality: _selectedMunicipality?.name ?? 'Antipolo',
        barangay: _selectedBarangay ?? '',
        street: _streetController.text.trim(),
        district: _selectedDistrict,
        area: _selectedArea,
        center: _selectedCenter,
        positions: _positionItems
            .where((item) => item.controller.text.trim().isNotEmpty)
            .map(
              (item) => MemberPosition(
                level: item.level,
                position: item.controller.text.trim(),
              ),
            )
            .toList(),
        membershipStatus: _membershipStatus,
        inactiveReason: _isInactive ? _inactiveReason.trim() : '',
        memberType: _memberType,
        dateJoined: DateFormat('yyyy-MM-dd').format(_selectedDateJoined),
        profileUrl: safeProfileUrl,
        signatureUrl: _signatureDeclined ? '' : _signatureBase64,
        signatureDeclined: _signatureDeclined,
        createdAt: nowStr,
        updatedAt: nowStr,
      );

      final newDocId = await _firestoreService.addMember(newMember);
      final createdMember = newMember.copyWith(id: newDocId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Text('Member ${newMember.fullName} registered!'),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(createdMember);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save member: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    final isDistrictLocked = _currentUser?.isDistrictLocked ?? false;
    final isAreaLocked = _currentUser?.isAreaLocked ?? false;
    final isCenterLocked = _currentUser?.isCenterLocked ?? false;

    final availableDistricts = _allCenters
        .map((c) => c.district)
        .toSet()
        .toList();
    if (availableDistricts.isEmpty ||
        !availableDistricts.contains(_selectedDistrict)) {
      availableDistricts.add(_selectedDistrict);
    }

    final availableAreas = _allCenters
        .where(
          (c) => c.district.toLowerCase() == _selectedDistrict.toLowerCase(),
        )
        .map((c) => c.area)
        .toSet()
        .toList();
    if (availableAreas.isEmpty || !availableAreas.contains(_selectedArea)) {
      availableAreas.add(_selectedArea);
    }

    final availableCenters = _allCenters
        .where(
          (c) =>
              c.district.toLowerCase() == _selectedDistrict.toLowerCase() &&
              c.area.toLowerCase() == _selectedArea.toLowerCase(),
        )
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.memberToEdit != null
              ? 'Edit Member Profile'
              : 'Register New Member',
        ),
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card 1: CHURCH JURISDICTION
              _buildSectionHeader('CHURCH JURISDICTION', primaryColor),
              const SizedBox(height: 10),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildDropdownField(
                        label: 'District',
                        value: _selectedDistrict,
                        items: availableDistricts,
                        enabled: !isDistrictLocked,
                        onChanged: isDistrictLocked
                            ? null
                            : (val) {
                                if (val != null) {
                                  setState(() {
                                    _selectedDistrict = val;
                                    final newAreas = _allCenters
                                        .where(
                                          (c) =>
                                              c.district.toLowerCase() ==
                                              val.toLowerCase(),
                                        )
                                        .map((c) => c.area)
                                        .toSet()
                                        .toList();
                                    if (newAreas.isNotEmpty) {
                                      _selectedArea = newAreas.first;
                                    }
                                  });
                                }
                              },
                      ),
                      const SizedBox(height: 12),
                      _buildDropdownField(
                        label: 'Area',
                        value: availableAreas.contains(_selectedArea)
                            ? _selectedArea
                            : availableAreas.first,
                        items: availableAreas,
                        enabled: !isAreaLocked,
                        onChanged: isAreaLocked
                            ? null
                            : (val) {
                                if (val != null) {
                                  setState(() {
                                    _selectedArea = val;
                                  });
                                }
                              },
                      ),
                      const SizedBox(height: 12),
                      _buildDropdownField(
                        label: 'Local Center',
                        value:
                            availableCenters.any(
                              (c) => c.centerName == _selectedCenter,
                            )
                            ? _selectedCenter
                            : (availableCenters.isNotEmpty
                                  ? availableCenters.first.centerName
                                  : _selectedCenter),
                        items: availableCenters.isNotEmpty
                            ? availableCenters.map((c) => c.centerName).toList()
                            : [_selectedCenter],
                        enabled: !isCenterLocked,
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
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // Card 2: PERSONAL INFORMATION
              _buildSectionHeader('PERSONAL INFORMATION', primaryColor),
              const SizedBox(height: 10),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // 1x1 Profile Photo Picker
                      Center(
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: _showImageSourceModal,
                              child: Stack(
                                children: [
                                  Container(
                                    width: 88,
                                    height: 88,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: primaryColor,
                                        width: 2,
                                      ),
                                      image:
                                          _currentProfileImageProvider != null
                                          ? DecorationImage(
                                              image:
                                                  _currentProfileImageProvider!,
                                              fit: BoxFit.cover,
                                            )
                                          : null,
                                      color: primaryColor.withValues(
                                        alpha: 0.12,
                                      ),
                                    ),
                                    child: _currentProfileImageProvider == null
                                        ? Icon(
                                            Icons.person_rounded,
                                            size: 44,
                                            color: primaryColor,
                                          )
                                        : null,
                                  ),
                                  Positioned(
                                    right: 0,
                                    bottom: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: primaryColor,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Theme.of(context).cardColor,
                                          width: 2,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt_rounded,
                                        size: 13,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: _showImageSourceModal,
                              child: Text(
                                _hasProfilePhoto
                                    ? 'Change Photo (1x1)'
                                    : 'Upload 1x1 Photo',
                                style: TextStyle(
                                  color: primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      _buildTextField(
                        label: 'Member ID',
                        controller: _memberIdController,
                        hintText: 'e.g. UECFI-2026-0001',
                        enabled: false,
                        validator: _isInactive
                            ? null
                            : (val) => (val == null || val.trim().isEmpty)
                                ? 'Member ID is required'
                                : null,
                      ),
                      const SizedBox(height: 12),

                      _buildTextField(
                        label: _isInactive ? 'First Name (Optional)' : 'First Name *',
                        controller: _firstNameController,
                        hintText: 'Enter first name',
                        validator: _isInactive
                            ? null
                            : (val) => (val == null || val.trim().isEmpty)
                                ? 'First name is required'
                                : null,
                      ),
                      const SizedBox(height: 12),

                      _buildTextField(
                        label: _isInactive
                            ? 'Middle Name (Optional)'
                            : 'Middle Name (Full Name Required)',
                        controller: _middleNameController,
                        hintText: 'e.g. Santos (full name, not initial like A.)',
                        validator: (val) {
                          if (_isInactive) return null;
                          if (val != null &&
                              val.trim().isNotEmpty &&
                              Member.isMiddleInitialOnly(val)) {
                            return 'Enter full middle name, not just initial "${val.trim()}"';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      _buildTextField(
                        label: _isInactive ? 'Last Name (Optional)' : 'Last Name *',
                        controller: _lastNameController,
                        hintText: 'Enter last name',
                        validator: _isInactive
                            ? null
                            : (val) => (val == null || val.trim().isEmpty)
                                ? 'Last name is required'
                                : null,
                      ),
                      const SizedBox(height: 12),

                      if (_nameDuplicates.isNotEmpty) ...[
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(
                              alpha: isDark ? 0.22 : 0.12,
                            ),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.amber.withValues(alpha: 0.5),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                size: 18,
                                color: Colors.amber.shade900,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'DUPLICATE MEMBER DETECTED',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                        color: Colors.amber.shade900,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      'A member with this exact name already exists in: '
                                      '${_nameDuplicates.map((d) => '${d.center.isNotEmpty ? d.center : "Unknown"} (${d.district} • ID: ${d.memberId})').join('; ')}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark
                                            ? Colors.white70
                                            : Colors.black87,
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      Row(
                        children: [
                          Expanded(
                            child: _buildDropdownField(
                              label: 'Gender',
                              value: _gender,
                              items: const ['Male', 'Female'],
                              onChanged: (val) {
                                if (val != null) setState(() => _gender = val);
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildDropdownField(
                              label: 'Civil Status',
                              value: _civilStatus,
                              items: const [
                                'Single',
                                'Married',
                                'Widowed',
                                'Separated',
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _civilStatus = val);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Date of Birth
                      InkWell(
                        onTap: () => _selectDob(context),
                        borderRadius: BorderRadius.circular(10),
                        child: IgnorePointer(
                          child: _buildTextField(
                            label: _isInactive
                                ? 'Date of Birth (Optional)'
                                : 'Date of Birth *',
                            controller: _dobController,
                            hintText: 'YYYY-MM-DD',
                            suffixIcon: const Icon(
                              Icons.calendar_today_rounded,
                              size: 18,
                            ),
                            validator: _isInactive
                                ? null
                                : (val) =>
                                    (val == null || val.trim().isEmpty)
                                    ? 'Date of birth is required'
                                    : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      _buildTextField(
                        label: _isInactive
                            ? 'Contact Number (Optional)'
                            : 'Contact Number *',
                        controller: _contactNoController,
                        hintText: 'e.g. 09123456789',
                        keyboardType: TextInputType.phone,
                        validator: _isInactive
                            ? null
                            : (val) => (val == null || val.trim().isEmpty)
                                ? 'Contact number is required'
                                : null,
                      ),
                      const SizedBox(height: 12),

                      _buildTextField(
                        label: 'Email Address',
                        controller: _emailController,
                        hintText: 'e.g. member@email.com',
                        keyboardType: TextInputType.emailAddress,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // Card 3: MINISTRY & ASSIGNED ROLE
              _buildSectionHeader('MINISTRY & ASSIGNED ROLE', primaryColor),
              const SizedBox(height: 10),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Computed Category Notice
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.auto_awesome_rounded,
                              size: 16,
                              color: primaryColor,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Auto-Computed Category: $_dynamicCategory',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: _buildDropdownField(
                              label: 'Membership Status',
                              value: _membershipStatus,
                              items: const ['Active', 'Inactive', 'Pending'],
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _membershipStatus = val);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildDropdownField(
                              label: 'Member Type',
                              value: _memberType,
                              items: const ['Regular', 'Old', 'New'],
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _memberType = val);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      if (_isInactive) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(
                              alpha: isDark ? 0.2 : 0.08,
                            ),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.blue.withValues(
                                alpha: isDark ? 0.4 : 0.25,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.info_outline_rounded,
                                size: 18,
                                color: Colors.blue,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Inactive Member: All profile information fields are optional. Only the reason for being inactive is required.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildDropdownField(
                          label: 'Reason for Being Inactive *',
                          value: _inactiveReasons.contains(_inactiveReason)
                              ? _inactiveReason
                              : _inactiveReasons.first,
                          items: _inactiveReasons,
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _inactiveReason = val);
                            }
                          },
                        ),
                      ],
                      const SizedBox(height: 16),

                      // Ministry Positions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Ministry Positions',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _positionItems.add(
                                  PositionFormItem(
                                    level: 'Local',
                                    initialPosition: '',
                                  ),
                                );
                              });
                            },
                            icon: const Icon(Icons.add_rounded, size: 16),
                            label: const Text(
                              'Add Position',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      ...List.generate(_positionItems.length, (index) {
                        final item = _positionItems[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 4,
                                child: _buildDropdownField(
                                  label: 'Level',
                                  value: item.level,
                                  items: const [
                                    'Local',
                                    'Area',
                                    'District',
                                    'National',
                                    'Auxiliary',
                                  ],
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() => item.level = val);
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 6,
                                child: _buildTextField(
                                  label: _isInactive
                                      ? 'Position Title'
                                      : 'Position Title *',
                                  controller: item.controller,
                                  hintText: 'e.g. Pastor, Deacon',
                                  validator: (val) =>
                                      !_isInactive &&
                                      index == 0 &&
                                      (val == null || val.trim().isEmpty)
                                          ? 'Required'
                                          : null,
                                ),
                              ),
                              if (_positionItems.length > 1) ...[
                                const SizedBox(width: 4),
                                Padding(
                                  padding: const EdgeInsets.only(top: 20),
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.remove_circle_outline_rounded,
                                      color: Colors.redAccent,
                                      size: 22,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        item.dispose();
                                        _positionItems.removeAt(index);
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // Card 4: RESIDENTIAL ADDRESS
              _buildSectionHeader('RESIDENTIAL ADDRESS', primaryColor),
              const SizedBox(height: 10),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Region
                      _buildDropdownFieldGeneric<Region>(
                        label: 'Region',
                        value: _selectedRegion,
                        items: philippineRegions,
                        itemLabel: (r) => r.regionName,
                        onChanged: (r) {
                          if (r != null) {
                            setState(() {
                              _selectedRegion = r;
                              _selectedProvince = r.provinces.isNotEmpty
                                  ? r.provinces.first
                                  : null;
                              _selectedMunicipality =
                                  (_selectedProvince != null &&
                                      _selectedProvince!
                                          .municipalities
                                          .isNotEmpty)
                                  ? _selectedProvince!.municipalities.first
                                  : null;
                              _selectedBarangay =
                                  (_selectedMunicipality != null &&
                                      _selectedMunicipality!
                                          .barangays
                                          .isNotEmpty)
                                  ? _selectedMunicipality!.barangays.first
                                  : null;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),

                      // Province
                      if (_selectedRegion != null &&
                          _selectedRegion!.provinces.isNotEmpty) ...[
                        _buildDropdownFieldGeneric<Province>(
                          label: 'Province',
                          value: _selectedProvince,
                          items: _selectedRegion!.provinces,
                          itemLabel: (p) => p.name,
                          onChanged: (p) {
                            if (p != null) {
                              setState(() {
                                _selectedProvince = p;
                                _selectedMunicipality =
                                    p.municipalities.isNotEmpty
                                    ? p.municipalities.first
                                    : null;
                                _selectedBarangay =
                                    (_selectedMunicipality != null &&
                                        _selectedMunicipality!
                                            .barangays
                                            .isNotEmpty)
                                    ? _selectedMunicipality!.barangays.first
                                    : null;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Municipality / City
                      if (_selectedProvince != null &&
                          _selectedProvince!.municipalities.isNotEmpty) ...[
                        _buildDropdownFieldGeneric<Municipality>(
                          label: 'Municipality / City',
                          value: _selectedMunicipality,
                          items: _selectedProvince!.municipalities,
                          itemLabel: (m) => m.name,
                          onChanged: (m) {
                            if (m != null) {
                              setState(() {
                                _selectedMunicipality = m;
                                _selectedBarangay = m.barangays.isNotEmpty
                                    ? m.barangays.first
                                    : null;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Barangay
                      if (_selectedMunicipality != null &&
                          _selectedMunicipality!.barangays.isNotEmpty) ...[
                        _buildDropdownField(
                          label: 'Barangay',
                          value:
                              _selectedBarangay ??
                              _selectedMunicipality!.barangays.first,
                          items: _selectedMunicipality!.barangays,
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedBarangay = val);
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                      ],

                      _buildTextField(
                        label: 'Street / House No. / Zone',
                        controller: _streetController,
                        hintText: 'Enter street address',
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // Card 5: DIGITAL SIGNATURE & ATTESTATION
              _buildSectionHeader(
                'DIGITAL SIGNATURE & ATTESTATION',
                primaryColor,
              ),
              const SizedBox(height: 10),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CheckboxListTile(
                        value: _signatureDeclined,
                        onChanged: (val) {
                          setState(() {
                            _signatureDeclined = val ?? false;
                          });
                        },
                        title: const Text(
                          'Decline to provide digital signature at this time',
                          style: TextStyle(fontSize: 13),
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      ),

                      if (!_signatureDeclined) ...[
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _showSignatureSourceModal,
                          child: Container(
                            height: 100,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white10
                                  : Colors.black.withValues(alpha: 0.04),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: primaryColor.withValues(alpha: 0.3),
                              ),
                            ),
                            child: _hasSignature
                                ? Center(
                                    child:
                                        _currentSignatureImageProvider != null
                                        ? Image(
                                            image:
                                                _currentSignatureImageProvider!,
                                            fit: BoxFit.contain,
                                            height: 80,
                                          )
                                        : null,
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.draw_rounded,
                                        size: 28,
                                        color: primaryColor,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Tap to draw or upload signature',
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          color: primaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              onPressed: _showSignatureSourceModal,
                              icon: const Icon(Icons.edit_rounded, size: 15),
                              label: Text(
                                _hasSignature ? 'Change Signature' : 'Sign Now',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _submitForm,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          widget.memberToEdit != null
                              ? Icons.save_rounded
                              : Icons.person_add_alt_1_rounded,
                          size: 20,
                        ),
                  label: Text(
                    widget.memberToEdit != null
                        ? 'SAVE PROFILE CHANGES'
                        : 'CREATE MEMBER RECORD',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
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

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    bool enabled = true,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? Colors.white54 : Colors.black54;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: textMuted,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          validator: validator,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: enabled ? null : (isDark ? Colors.white38 : Colors.black38),
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              fontSize: 13.5,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
            suffixIcon: enabled
                ? suffixIcon
                : const Icon(
                    Icons.lock_outline_rounded,
                    size: 16,
                    color: Colors.grey,
                  ),
            fillColor: !enabled
                ? (isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : Colors.black.withValues(alpha: 0.03))
                : null,
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?>? onChanged,
    bool enabled = true,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? Colors.white54 : Colors.black54;
    final selectedVal = items.contains(value)
        ? value
        : (items.isNotEmpty ? items.first : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: textMuted,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          key: ValueKey('$selectedVal-$enabled'),
          initialValue: selectedVal,
          isExpanded: true,
          icon: Icon(
            enabled
                ? Icons.keyboard_arrow_down_rounded
                : Icons.lock_outline_rounded,
            size: enabled ? 20 : 16,
            color: enabled ? null : (isDark ? Colors.white38 : Colors.black38),
          ),
          items: items
              .map(
                (item) => DropdownMenuItem(
                  value: item,
                  child: Text(
                    item,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: enabled
                          ? null
                          : (isDark ? Colors.white38 : Colors.black38),
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: enabled ? onChanged : null,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            fillColor: !enabled
                ? (isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : Colors.black.withValues(alpha: 0.03))
                : null,
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownFieldGeneric<T>({
    required String label,
    required T? value,
    required List<T> items,
    required String Function(T) itemLabel,
    required ValueChanged<T?> onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? Colors.white54 : Colors.black54;
    final selectedVal = items.contains(value)
        ? value
        : (items.isNotEmpty ? items.first : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: textMuted,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<T>(
          key: ValueKey(selectedVal),
          initialValue: selectedVal,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
          items: items
              .map(
                (item) => DropdownMenuItem<T>(
                  value: item,
                  child: Text(
                    itemLabel(item),
                    style: const TextStyle(fontSize: 13.5),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
          decoration: const InputDecoration(
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}
