import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_icon.dart';
import '../models/member.dart';
import '../screens/members/add_member_screen.dart';
import '../screens/portal/portal_menu_screen.dart';
import '../services/firestore_service.dart';

class PortalAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onMenuPressed;
  final VoidCallback? onAddPressed;
  final bool showMenuButton;
  @Deprecated('Use onAddPressed instead')
  final VoidCallback? onSearchPressed;

  const PortalAppBar({
    super.key,
    this.onMenuPressed,
    this.onAddPressed,
    this.onSearchPressed,
    this.showMenuButton = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 840;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final textPrimary = isDark
        ? const Color(0xFFF5F5FA)
        : const Color(0xFF0E0E14);

    return AppBar(
      backgroundColor: isDark ? const Color(0xFF16161F) : Colors.white,
      elevation: 0,
      scrolledUnderElevation: 1,
      centerTitle: false,
      automaticallyImplyLeading: showMenuButton,
      leading: showMenuButton
          ? IconButton(
              icon: AppIcon(
                icon: isDesktop
                    ? HugeIcons.strokeRoundedMoreHorizontal
                    : HugeIcons.strokeRoundedMenu01,
                size: 24,
                color: textPrimary,
              ),
              tooltip: isDesktop ? 'More / Portal Menu' : 'Portal Menu',
              onPressed:
                  onMenuPressed ??
                  () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const PortalMenuScreen(),
                      ),
                    );
                  },
            )
          : null,
      titleSpacing: 4,
      title: Text(
        'uecfi portal',
        style: GoogleFonts.plusJakartaSans(
          color: primaryColor,
          fontSize: 19,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
      actions: [
        StreamBuilder<Member?>(
          stream: FirestoreService().getCurrentMemberStream(),
          builder: (context, snapshot) {
            final currentMember = snapshot.data;
            final canAdd = currentMember == null || currentMember.canAddMembers;

            if (!canAdd) {
              return const SizedBox.shrink();
            }

            return IconButton(
              icon: AppIcon(
                icon: HugeIcons.strokeRoundedSquarePlus,
                size: 24,
                color: textPrimary,
              ),
              tooltip: 'Add Member',
              onPressed:
                  onAddPressed ??
                  () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const AddMemberScreen(),
                      ),
                    );
                  },
            );
          },
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}
