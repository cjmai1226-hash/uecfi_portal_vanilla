import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../widgets/app_icon.dart';
import '../../models/member.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../theme/theme.dart';
import '../../widgets/legal_about_sheet.dart';
import 'constitution_bylaws_screen.dart';
import '../posts/create_post_screen.dart';
import 'forms_templates_screen.dart';
import '../transfers/transfer_requests_screen.dart';

class PortalMenuScreen extends StatelessWidget {
  const PortalMenuScreen({super.key});

  void _showThemeDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? const Color(0xFFF5F5FA) : const Color(0xFF0E0E14);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final currentMode = ThemeService.instance.value;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Text(
                    'Select Appearance Theme',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                ListTile(
                  leading: AppIcon(
                    icon: HugeIcons.strokeRoundedSun03,
                    color: textPrimary,
                    size: 22,
                  ),
                  title: const Text('Light Mode'),
                  trailing: currentMode == ThemeMode.light
                      ? AppIcon(
                          icon: HugeIcons.strokeRoundedCheckmarkBadge01,
                          color: textPrimary,
                          size: 20,
                        )
                      : null,
                  onTap: () {
                    ThemeService.instance.setThemeMode(ThemeMode.light);
                    Navigator.of(ctx).pop();
                  },
                ),
                ListTile(
                  leading: AppIcon(
                    icon: HugeIcons.strokeRoundedMoon02,
                    color: textPrimary,
                    size: 22,
                  ),
                  title: const Text('Dark Mode'),
                  trailing: currentMode == ThemeMode.dark
                      ? AppIcon(
                          icon: HugeIcons.strokeRoundedCheckmarkBadge01,
                          color: textPrimary,
                          size: 20,
                        )
                      : null,
                  onTap: () {
                    ThemeService.instance.setThemeMode(ThemeMode.dark);
                    Navigator.of(ctx).pop();
                  },
                ),
                ListTile(
                  leading: AppIcon(
                    icon: HugeIcons.strokeRoundedComputer,
                    color: textPrimary,
                    size: 22,
                  ),
                  title: const Text('System Default'),
                  trailing: currentMode == ThemeMode.system
                      ? AppIcon(
                          icon: HugeIcons.strokeRoundedCheckmarkBadge01,
                          color: textPrimary,
                          size: 20,
                        )
                      : null,
                  onTap: () {
                    ThemeService.instance.setThemeMode(ThemeMode.system);
                    Navigator.of(ctx).pop();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Sign out of Portal'),
        content: const Text('Are you sure you want to sign out from District 3 Portal?'),
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
              Navigator.of(ctx).pop(); // Close dialog
              await AuthService().signOut();
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/login',
                  (route) => false,
                );
              }
            },
            child: const Text('Sign Out'),
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
    final borderColor = isDark ? const Color(0xFF262633) : const Color(0xFFE5E5ED);
    final currentUser = FirebaseAuth.instance.currentUser;

    return StreamBuilder<Member?>(
      stream: FirestoreService().getCurrentMemberStream(),
      builder: (context, snapshot) {
        final currentMember = snapshot.data;
        final userRole = currentMember?.role.toLowerCase() ?? '';
        final isAdmin = currentMember?.isAdmin ?? (userRole == 'admin');
        final isDistrictAdmin = currentMember?.isDistrictAdmin ??
            (userRole == 'district' || userRole == 'district_admin' || userRole == 'district admin');
        final canCreateDistrictPosts = isAdmin || isDistrictAdmin;
        final canManageTransfers = isAdmin || isDistrictAdmin;
        final canAccessAdminTools = canCreateDistrictPosts || canManageTransfers;
        final roleDisplayName = currentMember?.roleDisplayName ?? (isAdmin ? 'Administrator' : (isDistrictAdmin ? 'District Admin' : 'Member'));

        final fullName = currentMember != null && currentMember.fullName.trim().isNotEmpty
            ? currentMember.fullName.trim()
            : (currentUser?.displayName?.isNotEmpty == true
                ? currentUser!.displayName!
                : (currentUser?.email?.isNotEmpty == true
                    ? currentUser!.email!.split('@').first
                    : 'Administrator'));

        final memberIdText = currentMember != null && currentMember.memberId.isNotEmpty
            ? 'Member ID: ${currentMember.memberId}'
            : (currentUser?.email ?? 'Logged In');

        final imageProvider = currentMember?.profileImageProvider ??
            (currentUser?.photoURL != null && currentUser!.photoURL!.isNotEmpty
                ? NetworkImage(currentUser.photoURL!)
                : null);

        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Portal Menu',
              style: TextStyle(
                color: textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            elevation: 0,
            scrolledUnderElevation: 1,
            leading: IconButton(
              icon: AppIcon(
                icon: HugeIcons.strokeRoundedCancel01,
                size: 24,
                color: textPrimary,
              ),
              color: textPrimary,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User Profile Card with Role Badge
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF16161F) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor, width: 1.1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.08),
                        backgroundImage: imageProvider,
                        child: imageProvider == null
                            ? Text(
                                fullName.isNotEmpty ? fullName[0].toUpperCase() : 'U',
                                style: TextStyle(
                                  color: textPrimary,
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
                              fullName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              memberIdText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: borderColor),
                              ),
                              child: Text(
                                roleDisplayName.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: textPrimary,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Section 1: Administration and Tools (Filtered by Role)
                if (canAccessAdminTools) ...[
                  _buildSectionHeader(
                    title: 'ADMINISTRATION AND TOOLS',
                    color: textSecondary,
                  ),
                  const SizedBox(height: 6),
                  if (canCreateDistrictPosts) ...[
                    _buildMenuItem(
                      title: 'Create District Post',
                      subtitle: 'Publish announcements, updates, and pastoral letters',
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      icon: HugeIcons.strokeRoundedEdit02,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const CreatePostScreen()),
                        );
                      },
                    ),
                  ],
                  if (canManageTransfers) ...[
                    if (canCreateDistrictPosts) _buildDivider(borderColor),
                    StreamBuilder<int>(
                      stream: FirestoreService().getPendingTransfersCountStream(),
                      builder: (context, countSnapshot) {
                        final pendingCount = countSnapshot.data ?? 0;
                        return _buildMenuItem(
                          title: 'Transfer Requests',
                          subtitle: 'Review and verify member center transfers',
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                          icon: HugeIcons.strokeRoundedArrowLeftRight,
                          trailingWidget: pendingCount > 0
                              ? Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                  decoration: BoxDecoration(
                                    color: textPrimary,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '$pendingCount',
                                    style: TextStyle(
                                      color: isDark ? Colors.black : Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                              : null,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const TransferRequestsScreen()),
                            );
                          },
                        );
                      },
                    ),
                  ],
                  const SizedBox(height: 24),
                ],

                // Section 2: Documents and Forms
                _buildSectionHeader(
                  title: 'DOCUMENTS AND FORMS',
                  color: textSecondary,
                ),
                const SizedBox(height: 6),
                _buildMenuItem(
                  title: 'Forms and Templates',
                  subtitle: 'Member and center application forms and guidelines',
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  icon: HugeIcons.strokeRoundedFile01,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const FormsTemplatesScreen()),
                    );
                  },
                ),
                _buildDivider(borderColor),
                _buildMenuItem(
                  title: 'Constitution and bylaws',
                  subtitle: 'Official district governance and doctrinal bylaws',
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  icon: HugeIcons.strokeRoundedBook02,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ConstitutionBylawsScreen(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24),

                // Section 3: Legal and About
                _buildSectionHeader(
                  title: 'LEGAL AND ABOUT',
                  color: textSecondary,
                ),
                const SizedBox(height: 6),
                _buildMenuItem(
                  title: 'Terms of Service',
                  subtitle: 'User account terms, portal rules, and service conditions',
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  icon: HugeIcons.strokeRoundedLegalDocument01,
                  onTap: () => LegalAboutSheet.show(context, LegalDocType.termsOfService),
                ),
                _buildDivider(borderColor),
                _buildMenuItem(
                  title: 'Privacy Policy',
                  subtitle: 'Member record confidentiality and RA 10173 compliance',
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  icon: HugeIcons.strokeRoundedShieldCheck,
                  onTap: () => LegalAboutSheet.show(context, LegalDocType.privacyPolicy),
                ),
                _buildDivider(borderColor),
                _buildMenuItem(
                  title: 'Community Standards',
                  subtitle: 'Christ-centered code of conduct and communication ethics',
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  icon: HugeIcons.strokeRoundedChurch,
                  onTap: () => LegalAboutSheet.show(context, LegalDocType.communityStandards),
                ),
                _buildDivider(borderColor),
                _buildMenuItem(
                  title: 'About',
                  subtitle: 'Central District 3 Portal details and version information',
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  icon: HugeIcons.strokeRoundedInformationCircle,
                  onTap: () => LegalAboutSheet.show(context, LegalDocType.about),
                ),

                const SizedBox(height: 24),

                // Section 4: Preferences and System
                _buildSectionHeader(
                  title: 'PREFERENCES AND SYSTEM',
                  color: textSecondary,
                ),
                const SizedBox(height: 6),
                _buildMenuItem(
                  title: 'Appearance Theme',
                  subtitle: isDark ? 'Dark Theme' : 'Light Theme',
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  icon: HugeIcons.strokeRoundedPaintBoard,
                  onTap: () => _showThemeDialog(context),
                ),
                _buildDivider(borderColor),
                _buildMenuItem(
                  title: 'Sign out of Portal',
                  subtitle: 'End current session and return to login screen',
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  icon: HugeIcons.strokeRoundedLogout01,
                  onTap: () => _handleSignOut(context),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 4.0),
      child: Text(
        title,
        style: TextStyle(
          color: color,
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.4,
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required String title,
    required String subtitle,
    required Color textPrimary,
    required Color textSecondary,
    List<List<dynamic>>? icon,
    Color? iconColor,
    Color? chevronColor,
    Widget? trailingWidget,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: icon != null
          ? AppIcon(
              icon: icon,
              color: iconColor ?? textPrimary,
              size: 24,
            )
          : null,
      title: Text(
        title,
        style: TextStyle(
          color: textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 14.5,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: textSecondary,
          fontSize: 12.5,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingWidget != null) ...[
            trailingWidget,
            const SizedBox(width: 4),
          ],
          AppIcon(
            icon: HugeIcons.strokeRoundedArrowRight01,
            size: 18,
            color: chevronColor ?? textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(Color borderColor) {
    return Divider(
      height: 1,
      thickness: 1,
      color: borderColor,
      indent: 6,
      endIndent: 6,
    );
  }
}
