import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/banner_ad_widget.dart';
import '../constants/admin_constants.dart';
import 'admin_analytics_screen.dart';
import 'admin_jobs_screen.dart';
import 'admin_users_screen.dart';

class AdminHomeScreen extends ConsumerStatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  ConsumerState<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends ConsumerState<AdminHomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const AdminAnalyticsScreen(),
      const AdminUsersScreen(),
      const AdminJobsScreen(),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text(AdminConstants.dashboardTitle)),
      body: IndexedStack(index: _currentIndex, children: pages),
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
            ],
          ),
        ],
      ),
    );
  }
}
