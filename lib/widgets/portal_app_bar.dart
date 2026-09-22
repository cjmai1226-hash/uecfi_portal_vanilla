import 'package:flutter/material.dart';
import '../models/member.dart';
import '../screens/members/add_member_screen.dart';
import '../screens/portal/portal_menu_screen.dart';
import '../services/firestore_service.dart';

class PortalAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onMenuPressed;
  final VoidCallback? onAddPressed;
  @Deprecated('Use onAddPressed instead')
  final VoidCallback? onSearchPressed;

  const PortalAppBar({
    super.key,
    this.onMenuPressed,
    this.onAddPressed,
    this.onSearchPressed,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final textPrimary = isDark ? const Color(0xFFF5F5FA) : const Color(0xFF0E0E14);

    return AppBar(
      backgroundColor: isDark ? const Color(0xFF16161F) : Colors.white,
      elevation: 0,
      scrolledUnderElevation: 1,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.menu_rounded, size: 26),
        color: textPrimary,
        tooltip: 'Portal Menu',
        onPressed: onMenuPressed ??
            () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const PortalMenuScreen(),
                ),
              );
            },
      ),
      title: Image.asset(
        'assets/images/uecfi_logo.png',
        height: 38,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => Text(
          'UECFI',
          style: TextStyle(
            color: primaryColor,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      ),
      actions: [
        StreamBuilder<Member?>(
          stream: FirestoreService().getCurrentMemberStream(),
          builder: (context, snapshot) {
            final currentMember = snapshot.data;
            final canAdd = currentMember == null || currentMember.canAddMembers;

            if (!canAdd) {
              return const SizedBox(width: 8);
            }

            return IconButton(
              icon: const Icon(Icons.add_rounded, size: 26),
              color: textPrimary,
              tooltip: 'Add Member',
              onPressed: onAddPressed ??
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
        const SizedBox(width: 6),
      ],
    );
  }
}
