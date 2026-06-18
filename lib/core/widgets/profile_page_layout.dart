import 'package:flutter/material.dart';

import '../utils/extensions.dart';
import 'rozgar_shell_body.dart';

/// Scrollable profile body with correct inset below [GlassmorphicAppBar].
class ProfilePageLayout extends StatelessWidget {
  const ProfilePageLayout({
    super.key,
    required this.title,
    required this.actions,
    required this.body,
    this.header,
  });

  final String title;
  final List<Widget> actions;
  final Widget body;
  final Widget? header;

  @override
  Widget build(BuildContext context) {
    return RozgarShellBody(
      padding: EdgeInsets.fromLTRB(
        16,
        RozgarShellBody.topInset(context),
        16,
        0,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: context.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ...actions,
              ],
            ),
            if (header != null) ...[
              const SizedBox(height: 20),
              header!,
            ],
            const SizedBox(height: 20),
            body,
          ],
        ),
      ),
    );
  }
}

/// Card wrapper for profile sections.
class ProfileSectionCard extends StatelessWidget {
  const ProfileSectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: context.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: context.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: context.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

/// Hero header card for profile avatar and identity.
class ProfileHeroCard extends StatelessWidget {
  const ProfileHeroCard({
    super.key,
    required this.avatar,
    required this.name,
    required this.subtitle,
    this.badge,
  });

  final Widget avatar;
  final String name;
  final String subtitle;
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              context.colorScheme.primaryContainer,
              context.colorScheme.secondaryContainer.withValues(alpha: 0.6),
            ],
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            avatar,
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: context.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (badge != null) ...[
                    const SizedBox(height: 8),
                    badge!,
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
