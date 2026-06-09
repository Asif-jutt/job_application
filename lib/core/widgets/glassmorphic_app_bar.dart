import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../utils/extensions.dart';

class GlassmorphicAppBar extends StatelessWidget implements PreferredSizeWidget {
  const GlassmorphicAppBar({
    super.key,
    required this.title,
    this.avatarUrl,
    this.displayName,
    this.notificationCount = 0,
    this.onNotificationTap,
    this.onAvatarTap,
    this.actions,
    this.pinned = true,
  });

  final String title;
  final String? avatarUrl;
  final String? displayName;
  final int notificationCount;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onAvatarTap;
  final List<Widget>? actions;
  final bool pinned;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final isDark = context.theme.brightness == Brightness.dark;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.72),
            border: Border(
              bottom: BorderSide(
                color: context.colorScheme.primary.withValues(alpha: 0.12),
              ),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _AvatarButton(
                    url: avatarUrl,
                    name: displayName ?? title,
                    onTap: onAvatarTap,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          style: context.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (displayName != null)
                          Text(
                            displayName!,
                            style: context.textTheme.bodySmall?.copyWith(
                              color: context.colorScheme.primary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  _NotificationBadge(
                    count: notificationCount,
                    onTap: onNotificationTap,
                  ),
                  if (actions != null) ...actions!,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AvatarButton extends StatelessWidget {
  const _AvatarButton({this.url, required this.name, this.onTap});

  final String? url;
  final String name;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Hero(
        tag: 'profile_avatar',
        child: CircleAvatar(
          radius: 20,
          backgroundColor: context.colorScheme.primaryContainer,
          backgroundImage: url != null ? CachedNetworkImageProvider(url!) : null,
          child: url == null
              ? Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: context.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
      ),
    );
  }
}

class _NotificationBadge extends StatefulWidget {
  const _NotificationBadge({required this.count, this.onTap});

  final int count;
  final VoidCallback? onTap;

  @override
  State<_NotificationBadge> createState() => _NotificationBadgeState();
}

class _NotificationBadgeState extends State<_NotificationBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    if (widget.count > 0) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_NotificationBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.count > 0 && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (widget.count == 0) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: widget.onTap,
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.notifications_outlined),
          if (widget.count > 0)
            Positioned(
              right: -2,
              top: -2,
              child: ScaleTransition(
                scale: Tween<double>(begin: 1, end: 1.2).animate(
                  CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
                ),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: context.colorScheme.error,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    widget.count > 9 ? '9+' : '${widget.count}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
