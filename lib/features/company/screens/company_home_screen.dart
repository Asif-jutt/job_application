import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/widgets/banner_ad_widget.dart';
import '../../auth/provider/auth_provider.dart';
import '../provider/company_jobs_provider.dart';
import '../widgets/company_stat_card.dart';
import 'company_post_job_screen.dart';
import 'company_applications_screen.dart';
import 'company_profile_screen.dart';

class CompanyHomeScreen extends ConsumerStatefulWidget {
  const CompanyHomeScreen({super.key});

  @override
  ConsumerState<CompanyHomeScreen> createState() => _CompanyHomeScreenState();
}

class _CompanyHomeScreenState extends ConsumerState<CompanyHomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authNotifierProvider).value;

    final pages = [
      _DashboardTab(userName: user?.displayName ?? 'Company'),
      const CompanyPostJobScreen(),
      const CompanyApplicationsScreen(),
      const CompanyProfileScreen(),
    ];

    return Scaffold(
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
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: 'Dashboard',
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

class _DashboardTab extends ConsumerWidget {
  const _DashboardTab({required this.userName});
  final String userName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobsAsync = ref.watch(companyJobsProvider);

    return Scaffold(
      appBar: AppBar(title: Text('Welcome, $userName')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: jobsAsync.when(
                    data: (jobs) => CompanyStatCard(
                      title: 'Active Jobs',
                      value: '${jobs.length}',
                      icon: Icons.work,
                      color: context.colorScheme.primary,
                    ),
                    loading: () => const CompanyStatCard(
                      title: 'Active Jobs',
                      value: '...',
                      icon: Icons.work,
                      color: Colors.grey,
                    ),
                    error: (_, _) => const CompanyStatCard(
                      title: 'Active Jobs',
                      value: '0',
                      icon: Icons.work,
                      color: Colors.red,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: CompanyStatCard(
                    title: 'Applications',
                    value: '0',
                    icon: Icons.assignment,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
