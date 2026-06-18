import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/l10n/locale_provider.dart';
import '../utils/extensions.dart';

/// Globe icon button + bottom sheet to switch app language.
class LanguageSelectorButton extends ConsumerWidget {
  const LanguageSelectorButton({super.key});

  static Future<void> showSheet(BuildContext context, WidgetRef ref) {
    final strings = ref.read(stringsProvider);
    final current =
        AppLanguage.fromCode(ref.read(localeProvider).languageCode);

    return showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                strings.selectLanguage,
                style: ctx.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              ...AppLanguage.values.map((lang) {
                final selected = lang == current;
                return ListTile(
                  leading: Text(lang.flag, style: const TextStyle(fontSize: 24)),
                  title: Text(
                    lang.nativeName,
                    style: TextStyle(
                      fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(_englishLabel(lang)),
                  trailing: selected
                      ? Icon(Icons.check_circle, color: ctx.colorScheme.primary)
                      : null,
                  onTap: () {
                    ref.read(localeProvider.notifier).setLanguage(lang);
                    Navigator.pop(ctx);
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  static String _englishLabel(AppLanguage lang) => switch (lang) {
        AppLanguage.english => 'English',
        AppLanguage.urdu => 'Urdu',
        AppLanguage.hindi => 'Hindi',
        AppLanguage.arabic => 'Arabic',
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = AppLanguage.fromCode(ref.watch(localeProvider).languageCode);
    return IconButton(
      tooltip: ref.watch(stringsProvider).language,
      onPressed: () => showSheet(context, ref),
      icon: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.language, size: 22),
          const SizedBox(width: 2),
          Text(lang.flag, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}
