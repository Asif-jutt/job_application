import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/route_constants.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/widgets/animated_switcher_widget.dart';
import '../../../core/widgets/banner_ad_widget.dart';
import '../../../core/widgets/glassmorphic_app_bar.dart';
import '../../../core/widgets/rozgar_drawer.dart';
import '../../auth/provider/auth_provider.dart';
import 'company_applications_screen.dart';
import 'company_job_creator_screen.dart';
import 'company_jobs_screen.dart';
import 'company_profile_screen.dart';

class CompanyHomeScreen extends ConsumerStatefulWidget {
  const CompanyHomeScreen({super.key});

  @override
  ConsumerState<CompanyHomeScreen> createState() => _CompanyHomeScreenState();
}

class _CompanyHomeScreenState extends ConsumerState<CompanyHomeScreen> {
  int _currentIndex = 0;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authNotifierProvider).value;

    final pages = [
      const CompanyJobsScreen(),
      const CompanyJobCreatorScreen(),
      const CompanyApplicationsScreen(),
      const CompanyProfileScreen(),
    ];

    const titles = ['My Jobs', 'Post Job', 'Applicants', 'Profile'];

    return Scaffold(
      key: _scaffoldKey,
      extendBodyBehindAppBar: true,
      drawer: RozgarDrawer(
        currentRoute: RouteConstants.companyHome,
        items: const [
          DrawerNavItem(
            route: RouteConstants.companyHome,
            label: 'My Jobs',
            icon: Icons.work_outline,
          ),
          DrawerNavItem(
            route: RouteConstants.companyPostJob,
            label: 'Post Job',
            icon: Icons.add_circle_outline,
          ),
          DrawerNavItem(
            route: RouteConstants.companyApplications,
            label: 'Applicants',
            icon: Icons.people_outline,
          ),
          DrawerNavItem(
            route: RouteConstants.companyProfile,
            label: 'Company Profile',
            icon: Icons.business_outlined,
          ),
        ],
        onNavigate: (route) {
          final index = switch (route) {
            RouteConstants.companyPostJob => 1,
            RouteConstants.companyApplications => 2,
            RouteConstants.companyProfile => 3,
            _ => 0,
          };
          setState(() => _currentIndex = index);
        },
      ),
      appBar: GlassmorphicAppBar(
        title: titles[_currentIndex],
        displayName: user?.displayName,
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
                icon: Icon(Icons.work_outline),
                selectedIcon: Icon(Icons.work),
                label: 'My Jobs',
              ),
              NavigationDestination(
                icon: Icon(Icons.add_circle_outline),
                selectedIcon: Icon(Icons.add_circle),
                label: 'Post Job',
              ),
              NavigationDestination(
                icon: Icon(Icons.people_outline),
                selectedIcon: Icon(Icons.people),
                label: 'Applicants',
              ),
              NavigationDestination(
                icon: Icon(Icons.business_outlined),
                selectedIcon: Icon(Icons.business),
                label: 'Profile',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

