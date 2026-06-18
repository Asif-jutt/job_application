import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/route_constants.dart';
import '../../../core/constants/l10n/locale_provider.dart';
import '../../../core/widgets/animated_switcher_widget.dart';
import '../../../core/widgets/banner_ad_widget.dart';
import '../../../core/widgets/glassmorphic_app_bar.dart';
import '../../../core/widgets/home_app_bar_actions.dart';
import '../../../core/widgets/rozgar_drawer.dart';
import '../../../core/widgets/skippable_ad_overlay.dart';
import '../../auth/provider/auth_provider.dart';
import 'user_applications_screen.dart';
import 'user_chat_list_screen.dart';
import 'user_jobs_screen.dart';
import 'user_profile_screen.dart';

class UserHomeScreen extends ConsumerStatefulWidget {
  const UserHomeScreen({super.key});

  @override
  ConsumerState<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends ConsumerState<UserHomeScreen> {
  int _currentIndex = 0;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) scheduleSkippableAd(context, ref);
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authNotifierProvider).value;
    final s = ref.watch(stringsProvider);

    final pages = [
      const UserJobsScreen(),
      const UserApplicationsScreen(),
      const UserChatListScreen(),
      const UserProfileScreen(),
    ];

    final titles = [s.discoverJobs, s.applications, s.messages, s.profile];

    return Scaffold(
      key: _scaffoldKey,
      extendBodyBehindAppBar: true,
      drawer: RozgarDrawer(
        currentRoute: RouteConstants.userHome,
        items: [
          DrawerNavItem(
            route: RouteConstants.userHome,
            label: s.jobsFeed,
            icon: Icons.work_outline,
          ),
          DrawerNavItem(
            route: '${RouteConstants.userHome}/applications',
            label: s.myApplications,
            icon: Icons.assignment_outlined,
          ),
          DrawerNavItem(
            route: RouteConstants.userChats,
            label: s.messages,
            icon: Icons.chat_bubble_outline,
          ),
          DrawerNavItem(
            route: RouteConstants.userProfile,
            label: s.profile,
            icon: Icons.person_outline,
          ),
        ],
        onNavigate: (route) {
          final index = switch (route) {
            '${RouteConstants.userHome}/applications' => 1,
            RouteConstants.userChats => 2,
            RouteConstants.userProfile => 3,
            _ => 0,
          };
          setState(() => _currentIndex = index);
        },
      ),
      appBar: GlassmorphicAppBar(
        title: titles[_currentIndex],
        displayName: user?.displayName,
        notificationCount: 2,
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
                label: s.jobs,
              ),
              NavigationDestination(
                icon: const Icon(Icons.assignment_outlined),
                selectedIcon: const Icon(Icons.assignment),
                label: s.applied,
              ),
              NavigationDestination(
                icon: const Icon(Icons.chat_bubble_outline),
                selectedIcon: const Icon(Icons.chat_bubble),
                label: s.messages,
              ),
              NavigationDestination(
                icon: const Icon(Icons.person_outline),
                selectedIcon: const Icon(Icons.person),
                label: s.profile,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
