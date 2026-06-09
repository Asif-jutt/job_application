import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/route_constants.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/widgets/animated_switcher_widget.dart';
import '../../../core/widgets/banner_ad_widget.dart';
import '../../../core/widgets/glassmorphic_app_bar.dart';
import '../../../core/widgets/rozgar_drawer.dart';
import '../../auth/provider/auth_provider.dart';
import '../constants/admin_constants.dart';
import 'admin_analytics_screen.dart';
import 'admin_diagnostics_screen.dart';
import 'admin_jobs_screen.dart';
import 'admin_profile_screen.dart';
import 'admin_users_screen.dart';

class AdminHomeScreen extends ConsumerStatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  ConsumerState<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends ConsumerState<AdminHomeScreen> {
  int _currentIndex = 0;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authNotifierProvider).value;

    final pages = [
      const AdminAnalyticsScreen(),
      const AdminUsersScreen(),
      const AdminJobsScreen(),
      const AdminDiagnosticsScreen(),
      const AdminProfileScreen(),
    ];

    const titles = [
      AdminConstants.dashboardTitle,
      AdminConstants.usersTab,
      AdminConstants.jobsTab,
      'System',
      'Profile',
    ];

    return Scaffold(
      key: _scaffoldKey,
      extendBodyBehindAppBar: true,
      drawer: RozgarDrawer(
        currentRoute: RouteConstants.adminHome,
        items: const [
          DrawerNavItem(
            route: RouteConstants.adminHome,
            label: AdminConstants.analyticsTab,
            icon: Icons.analytics_outlined,
          ),
          DrawerNavItem(
            route: RouteConstants.adminUsers,
            label: AdminConstants.usersTab,
            icon: Icons.people_outline,
          ),
          DrawerNavItem(
            route: RouteConstants.adminJobs,
            label: AdminConstants.jobsTab,
            icon: Icons.work_outline,
          ),
          DrawerNavItem(
            route: RouteConstants.adminAnalytics,
            label: 'System Diagnostics',
            icon: Icons.health_and_safety_outlined,
          ),
          DrawerNavItem(
            route: RouteConstants.adminProfile,
            label: 'Admin Profile',
            icon: Icons.admin_panel_settings_outlined,
          ),
        ],
        onNavigate: (route) {
          final index = switch (route) {
            RouteConstants.adminUsers => 1,
            RouteConstants.adminJobs => 2,
            RouteConstants.adminAnalytics => 3,
            RouteConstants.adminProfile => 4,
            _ => 0,
          };
          setState(() => _currentIndex = index);
        },
      ),
      appBar: GlassmorphicAppBar(
        title: titles[_currentIndex],
        displayName: user?.displayName ?? 'Admin',
        onAvatarTap: () => _scaffoldKey.currentState?.openDrawer(),
        actions: [
          IconButton(
            icon: Icon(
              Theme.of(context).brightness == Brightness.dark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
            ),
            onPressed: () {
              final current = ref.read(themeModeProvider);
              ref.read(themeModeProvider.notifier).state =
                  current == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
            },
          ),
        ],
      ),
      body: AnimatedSwitcherWidget(child: pages[_currentIndex]),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const BannerAdWidget(),
          NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (i) => setState(() => _currentIndex = i),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.analytics_outlined),
                selectedIcon: Icon(Icons.analytics),
                label: AdminConstants.analyticsTab,
              ),
              NavigationDestination(
                icon: Icon(Icons.people_outline),
                selectedIcon: Icon(Icons.people),
                label: AdminConstants.usersTab,
              ),
              NavigationDestination(
                icon: Icon(Icons.work_outline),
                selectedIcon: Icon(Icons.work),
                label: AdminConstants.jobsTab,
              ),
              NavigationDestination(
                icon: Icon(Icons.health_and_safety_outlined),
                selectedIcon: Icon(Icons.health_and_safety),
                label: 'System',
              ),
              NavigationDestination(
                icon: Icon(Icons.admin_panel_settings_outlined),
                selectedIcon: Icon(Icons.admin_panel_settings),
                label: 'Profile',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
