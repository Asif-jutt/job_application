import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/theme_provider.dart';
import 'language_selector.dart';

/// Standard AppBar actions: language switcher + theme toggle.
List<Widget> homeAppBarActions(BuildContext context, WidgetRef ref) {
  return [
    const LanguageSelectorButton(),
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
  ];
}
