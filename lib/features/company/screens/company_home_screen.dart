import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/route_constants.dart';
import '../../../core/constants/l10n/locale_provider.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/widgets/animated_switcher_widget.dart';
import '../../../core/widgets/banner_ad_widget.dart';
import '../../../core/widgets/glassmorphic_app_bar.dart';
import '../../../core/widgets/home_app_bar_actions.dart';
import '../../../core/widgets/rozgar_drawer.dart';
import '../../auth/provider/auth_provider.dart';
import 'company_applications_screen.dart';
import 'company_chat_list_screen.dart';
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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _linkSeedJobs());
  }

  Future<void> _linkSeedJobs() async {
    final user = ref.read(authNotifierProvider).value;
    if (user == null) return;
    await ref.read(jobSeedServiceProvider).linkSeedJobsToCompany(user.uid);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authNotifierProvider).value;
    final s = ref.watch(stringsProvider);

    final pages = [
      const CompanyJobsScreen(),
      const CompanyJobCreatorScreen(),
      const CompanyApplicationsScreen(),
      const CompanyChatListScreen(),
      const CompanyProfileScreen(),
    ];

    final titles = [
      s.myJobs,
      s.postJob,
      s.applicants,
      s.messages,
      s.profile,
    ];

    return Scaffold(
      key: _scaffoldKey,
      extendBodyBehindAppBar: true,
      drawer: RozgarDrawer(
        currentRoute: RouteConstants.companyHome,
        items: [
          DrawerNavItem(
            route: RouteConstants.companyHome,
            label: s.myJobs,
            icon: Icons.work_outline,
          ),
          DrawerNavItem(
            route: RouteConstants.companyPostJob,
            label: s.postJob,
            icon: Icons.add_circle_outline,
          ),
          DrawerNavItem(
            route: RouteConstants.companyApplications,
            label: s.applicants,
            icon: Icons.people_outline,
          ),
          DrawerNavItem(
            route: RouteConstants.companyChats,
            label: s.messages,
            icon: Icons.chat_bubble_outline,
          ),
          DrawerNavItem(
            route: RouteConstants.companyProfile,
            label: s.companyProfile,
            icon: Icons.business_outlined,
          ),
        ],
        onNavigate: (route) {
          final index = switch (route) {
            RouteConstants.companyPostJob => 1,
            RouteConstants.companyApplications => 2,
            RouteConstants.companyChats => 3,
            RouteConstants.companyProfile => 4,
            _ => 0,
          };
          setState(() => _currentIndex = index);
        },
      ),
      appBar: GlassmorphicAppBar(
        title: titles[_currentIndex],
        displayName: user?.displayName,
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
                icon: const Icon(Icons.work_outline),
                selectedIcon: const Icon(Icons.work),
                label: s.myJobs,
              ),
              NavigationDestination(
                icon: const Icon(Icons.add_circle_outline),
                selectedIcon: const Icon(Icons.add_circle),
                label: s.postJob,
              ),
              NavigationDestination(
                icon: const Icon(Icons.people_outline),
                selectedIcon: const Icon(Icons.people),
                label: s.applicants,
              ),
              NavigationDestination(
                icon: const Icon(Icons.chat_bubble_outline),
                selectedIcon: const Icon(Icons.chat_bubble),
                label: s.messages,
              ),
              NavigationDestination(
                icon: const Icon(Icons.business_outlined),
                selectedIcon: const Icon(Icons.business),
                label: s.profile,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
