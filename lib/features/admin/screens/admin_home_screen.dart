import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/route_constants.dart';
import '../../../core/constants/l10n/locale_provider.dart';
import '../../../core/widgets/animated_switcher_widget.dart';
import '../../../core/widgets/banner_ad_widget.dart';
import '../../../core/widgets/glassmorphic_app_bar.dart';
import '../../../core/widgets/home_app_bar_actions.dart';
import '../../../core/widgets/rozgar_drawer.dart';
import '../../auth/provider/auth_provider.dart';
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
    final s = ref.watch(stringsProvider);

    final pages = [
      const AdminAnalyticsScreen(),
      const AdminUsersScreen(),
      const AdminJobsScreen(),
      const AdminDiagnosticsScreen(),
      const AdminProfileScreen(),
    ];

    final titles = [
      s.analytics,
      s.users,
      s.allJobs,
      s.system,
      s.profile,
    ];

    return Scaffold(
      key: _scaffoldKey,
      extendBodyBehindAppBar: true,
      drawer: RozgarDrawer(
        currentRoute: RouteConstants.adminHome,
        items: [
          DrawerNavItem(
            route: RouteConstants.adminHome,
            label: s.analytics,
            icon: Icons.analytics_outlined,
          ),
          DrawerNavItem(
            route: RouteConstants.adminUsers,
            label: s.users,
            icon: Icons.people_outline,
          ),
          DrawerNavItem(
            route: RouteConstants.adminJobs,
            label: s.allJobs,
            icon: Icons.work_outline,
          ),
          DrawerNavItem(
            route: RouteConstants.adminAnalytics,
            label: s.systemDiagnostics,
            icon: Icons.health_and_safety_outlined,
          ),
          DrawerNavItem(
            route: RouteConstants.adminProfile,
            label: s.adminProfile,
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
        actions: homeAppBarActions(context, ref),
      ),
      body: AnimatedSwitcherWidget(child: pages[_currentIndex]),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const BannerAdWidget(),
          NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (i) => setState(() => _currentIndex = i),
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.analytics_outlined),
                selectedIcon: const Icon(Icons.analytics),
                label: s.analytics,
              ),
              NavigationDestination(
                icon: const Icon(Icons.people_outline),
                selectedIcon: const Icon(Icons.people),
                label: s.users,
              ),
              NavigationDestination(
                icon: const Icon(Icons.work_outline),
                selectedIcon: const Icon(Icons.work),
                label: s.allJobs,
              ),
              NavigationDestination(
                icon: const Icon(Icons.health_and_safety_outlined),
                selectedIcon: const Icon(Icons.health_and_safety),
                label: s.system,
              ),
              NavigationDestination(
                icon: const Icon(Icons.admin_panel_settings_outlined),
                selectedIcon: const Icon(Icons.admin_panel_settings),
                label: s.profile,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
