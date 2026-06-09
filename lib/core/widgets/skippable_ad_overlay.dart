import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../providers/core_providers.dart';
import '../utils/extensions.dart';

/// Professional full-screen promo with large ad, 5s skip, and X close.
class SkippableAdOverlay extends ConsumerStatefulWidget {
  const SkippableAdOverlay({super.key, required this.onDismiss});

  final VoidCallback onDismiss;

  @override
  ConsumerState<SkippableAdOverlay> createState() =>
      _SkippableAdOverlayState();
}

class _SkippableAdOverlayState extends ConsumerState<SkippableAdOverlay>
    with SingleTickerProviderStateMixin {
  static const _skipAfterSeconds = 5;

  BannerAd? _largeAd;
  bool _adLoaded = false;
  int _elapsed = 0;
  Timer? _timer;
  late AnimationController _fadeController;

  bool get _canSkip => _elapsed >= _skipAfterSeconds;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _loadLargeAd();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _elapsed++);
      if (_elapsed >= _skipAfterSeconds + 15) {
        t.cancel();
        widget.onDismiss();
      }
    });
  }

  void _loadLargeAd() {
    _largeAd = ref.read(adsServiceProvider).createLargeBannerAd(
          onAdLoaded: (_) {
            if (mounted) setState(() => _adLoaded = true);
          },
        );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _largeAd?.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = (_skipAfterSeconds - _elapsed).clamp(0, _skipAfterSeconds);

    return FadeTransition(
      opacity: _fadeController,
      child: Material(
        color: Colors.black.withValues(alpha: 0.94),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Sponsored',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: widget.onDismiss,
                      icon: const Icon(Icons.close, color: Colors.white),
                      tooltip: 'Close',
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: _adLoaded && _largeAd != null
                      ? Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: context.colorScheme.primary
                                    .withValues(alpha: 0.35),
                                blurRadius: 30,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: ColoredBox(
                              color: Colors.white,
                              child: SizedBox(
                                width: _largeAd!.size.width.toDouble(),
                                height: _largeAd!.size.height.toDouble(),
                                child: AdWidget(ad: _largeAd!),
                              ),
                            ),
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(color: Colors.white),
                            const SizedBox(height: 16),
                            Text(
                              'Loading promotion...',
                              style: context.textTheme.bodyLarge?.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      'Rozgar — Your Professional Job Network',
                      style: context.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _canSkip ? widget.onDismiss : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: _canSkip
                              ? context.colorScheme.primary
                              : Colors.grey.shade700,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          _canSkip
                              ? 'Skip Ad'
                              : 'Skip in ${remaining}s',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Schedules skippable ad ~2.5 minutes after session start.
void scheduleSkippableAd(BuildContext context, WidgetRef ref) {
  if (kIsWeb) return;
  if (ref.read(adOverlayShownProvider)) return;

  Future.delayed(const Duration(minutes: 2, seconds: 30), () {
    if (!context.mounted) return;
    showSkippableAdIfNeeded(context, ref);
  });
}

void showSkippableAdIfNeeded(BuildContext context, WidgetRef ref) {
  if (kIsWeb) return;
  if (ref.read(adOverlayShownProvider)) return;
  ref.read(adOverlayShownProvider.notifier).state = true;

  Navigator.of(context).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierDismissible: false,
      pageBuilder: (_, _, _) => SkippableAdOverlay(
        onDismiss: () => Navigator.of(context).pop(),
      ),
      transitionsBuilder: (_, animation, _, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    ),
  );
}

final adOverlayShownProvider = StateProvider<bool>((ref) => false);
