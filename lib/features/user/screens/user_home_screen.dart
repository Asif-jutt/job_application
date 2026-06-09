import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/route_constants.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/widgets/animated_switcher_widget.dart';
import '../../../core/widgets/banner_ad_widget.dart';
import '../../../core/widgets/glassmorphic_app_bar.dart';
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
    final pages = [
      const UserJobsScreen(),
      const UserApplicationsScreen(),
      const UserChatListScreen(),
      const UserProfileScreen(),
    ];

    const titles = ['Discover Jobs', 'Applications', 'Messages', 'Profile'];

    return Scaffold(
      key: _scaffoldKey,
      extendBodyBehindAppBar: true,
      drawer: RozgarDrawer(
        currentRoute: RouteConstants.userHome,
        items: const [
          DrawerNavItem(
            route: RouteConstants.userHome,
            label: 'Jobs Feed',
            icon: Icons.work_outline,
          ),
          DrawerNavItem(
            route: '${RouteConstants.userHome}/applications',
            label: 'My Applications',
            icon: Icons.assignment_outlined,
          ),
          DrawerNavItem(
            route: RouteConstants.userChats,
            label: 'Messages',
            icon: Icons.chat_bubble_outline,
          ),
          DrawerNavItem(
            route: RouteConstants.userProfile,
            label: 'Profile',
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
                label: 'Jobs',
              ),
              NavigationDestination(
                icon: Icon(Icons.assignment_outlined),
                selectedIcon: Icon(Icons.assignment),
                label: 'Applied',
              ),
              NavigationDestination(
                icon: Icon(Icons.chat_bubble_outline),
                selectedIcon: Icon(Icons.chat_bubble),
                label: 'Messages',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
