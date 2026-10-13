import 'package:flutter/material.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/portal_app_bar.dart';
import '../finance/finance_screen.dart';
import 'home_screen.dart';
import '../members/members_directory_screen.dart';
import '../portal/portal_menu_screen.dart';
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
    final isDesktop = MediaQuery.sizeOf(context).width >= 840;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final unselectedColor = isDark ? const Color(0xFF9E9EB2) : const Color(0xFF6B6B80);
    final railBgColor = isDark ? const Color(0xFF16161F) : Colors.white;
    final dividerColor = isDark ? const Color(0xFF232332) : const Color(0xFFE5E7EB);

    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              backgroundColor: railBgColor,
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              labelType: NavigationRailLabelType.all,
              groupAlignment: -0.85,
              minWidth: 76,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    'assets/images/uecfi_pmm_logo.png',
                    width: 38,
                    height: 38,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              trailing: Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: IconButton(
                  icon: AppIcon(
                    icon: HugeIcons.strokeRoundedMoreHorizontal,
                    color: unselectedColor,
                    size: 24,
                  ),
                  tooltip: 'More / Portal Menu',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const PortalMenuScreen(),
                      ),
                    );
                  },
                ),
              ),
              indicatorColor: primaryColor.withValues(alpha: isDark ? 0.22 : 0.12),
              destinations: [
                NavigationRailDestination(
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
                  label: const Text('Home'),
                ),
                NavigationRailDestination(
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
                  label: const Text('Members'),
                ),
                NavigationRailDestination(
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
                  label: const Text('Finance'),
                ),
                NavigationRailDestination(
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
                  label: const Text('Stats'),
                ),
              ],
            ),
            VerticalDivider(
              thickness: 1,
              width: 1,
              color: dividerColor,
            ),
            Expanded(
              child: Scaffold(
                appBar: const PortalAppBar(showMenuButton: false),
                body: IndexedStack(
                  index: _currentIndex,
                  children: _screens,
                ),
              ),
            ),
          ],
        ),
      );
    }

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
