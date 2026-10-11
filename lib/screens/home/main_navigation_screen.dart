import 'package:flutter/material.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/portal_app_bar.dart';
import '../finance/finance_screen.dart';
import 'home_screen.dart';
import '../members/members_directory_screen.dart';
import '../stats/stats_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    MembersDirectoryScreen(),
    FinanceScreen(),
    StatsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final unselectedColor = isDark ? const Color(0xFF9E9EB2) : const Color(0xFF6B6B80);

    return Scaffold(
      appBar: const PortalAppBar(),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: isDark ? const Color(0xFF16161F) : Colors.white,
        indicatorColor: primaryColor.withValues(alpha: isDark ? 0.22 : 0.12),
        elevation: 6,
        destinations: [
          NavigationDestination(
            icon: AppIcon(
              icon: HugeIcons.strokeRoundedHome01,
              color: unselectedColor,
              size: 24,
            ),
            selectedIcon: AppIcon(
              icon: HugeIcons.strokeRoundedHome01,
              color: primaryColor,
              size: 24,
            ),
            label: 'Home',
          ),
          NavigationDestination(
            icon: AppIcon(
              icon: HugeIcons.strokeRoundedUserGroup,
              color: unselectedColor,
              size: 24,
            ),
            selectedIcon: AppIcon(
              icon: HugeIcons.strokeRoundedUserGroup,
              color: primaryColor,
              size: 24,
            ),
            label: 'Members',
          ),
          NavigationDestination(
            icon: AppIcon(
              icon: HugeIcons.strokeRoundedWallet01,
              color: unselectedColor,
              size: 24,
            ),
            selectedIcon: AppIcon(
              icon: HugeIcons.strokeRoundedWallet01,
              color: primaryColor,
              size: 24,
            ),
            label: 'Finance',
          ),
          NavigationDestination(
            icon: AppIcon(
              icon: HugeIcons.strokeRoundedAnalytics01,
              color: unselectedColor,
              size: 24,
            ),
            selectedIcon: AppIcon(
              icon: HugeIcons.strokeRoundedAnalytics01,
              color: primaryColor,
              size: 24,
            ),
            label: 'Stats',
          ),
        ],
      ),
    );
  }
}
