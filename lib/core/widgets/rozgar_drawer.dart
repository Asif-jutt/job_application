import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/provider/auth_provider.dart';
import '../constants/app_constants.dart';
import '../constants/l10n/locale_provider.dart';
import '../models/user_role.dart';
import '../utils/extensions.dart';
import 'language_selector.dart';

class RozgarDrawer extends ConsumerStatefulWidget {
  const RozgarDrawer({
    super.key,
    required this.currentRoute,
    required this.items,
    this.onNavigate,
  });

  final String currentRoute;
  final List<DrawerNavItem> items;
  final void Function(String route)? onNavigate;

  @override
  ConsumerState<RozgarDrawer> createState() => _RozgarDrawerState();
}

class _RozgarDrawerState extends ConsumerState<RozgarDrawer> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authNotifierProvider).value;
    final role = user?.role ?? UserRole.user;
    final strings = ref.watch(stringsProvider);
    final roleLabel = switch (role) {
      UserRole.user => strings.roleJobSeeker,
      UserRole.company => strings.roleRecruiter,
      UserRole.admin => strings.roleAdmin,
    };

    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              context.colorScheme.primary,
              context.colorScheme.secondary,
              context.colorScheme.tertiary.withValues(alpha: 0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.work_outline_rounded,
                        color: Colors.white, size: 36),
                    const SizedBox(height: 8),
                    Text(
                      AppConstants.appName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      roleLabel,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 13,
                      ),
                    ),
                    if (user != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        user.displayName ?? user.email,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: context.colorScheme.surface,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    children: widget.items.map((item) {
                      final isActive = widget.currentRoute.startsWith(item.route);
                      return _DrawerTile(
                        item: item,
                        isActive: isActive,
                        onTap: () {
                          Navigator.pop(context);
                          widget.onNavigate?.call(item.route);
                        },
                      );
                    }).toList(),
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.language),
                title: Text(strings.language),
                onTap: () => LanguageSelectorButton.showSheet(context, ref),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    ref.read(authNotifierProvider.notifier).signOut();
                  },
                  icon: const Icon(Icons.logout),
                  label: Text(strings.signOut),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.colorScheme.error,
                    side: BorderSide(color: context.colorScheme.error),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DrawerNavItem {
  const DrawerNavItem({
    required this.route,
    required this.label,
    required this.icon,
  });

  final String route;
  final String label;
  final IconData icon;
}

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  final DrawerNavItem item;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isActive
            ? context.colorScheme.primary.withValues(alpha: 0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isActive
            ? Border.all(color: context.colorScheme.primary.withValues(alpha: 0.3))
            : null,
      ),
      child: ListTile(
        leading: Icon(
          item.icon,
          color: isActive ? context.colorScheme.primary : Colors.grey.shade600,
        ),
        title: Text(
          item.label,
          style: TextStyle(
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            color: isActive ? context.colorScheme.primary : null,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: onTap,
      ),
    );
  }
}
