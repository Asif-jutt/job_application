import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

export 'app_strings.dart';
import 'app_strings.dart';

const _localeKey = 'rozgar_locale';

/// Supported app languages.
enum AppLanguage {
  english('en', 'English', '🇬🇧'),
  urdu('ur', 'اردو', '🇵🇰'),
  hindi('hi', 'हिन्दी', '🇮🇳'),
  arabic('ar', 'العربية', '🇸🇦');

  const AppLanguage(this.code, this.nativeName, this.flag);
  final String code;
  final String nativeName;
  final String flag;

  Locale get locale => Locale(code);

  static AppLanguage fromCode(String? code) {
    return AppLanguage.values.firstWhere(
      (l) => l.code == code,
      orElse: () => AppLanguage.english,
    );
  }

  bool get isRtl => this == AppLanguage.urdu || this == AppLanguage.arabic;
}

final supportedLocales = AppLanguage.values.map((l) => l.locale).toList();

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});

final stringsProvider = Provider<AppStrings>((ref) {
  final locale = ref.watch(localeProvider);
  return AppStrings(locale.languageCode);
});

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(AppLanguage.english.locale) {
    _loadSaved();
  }

  AppLanguage get currentLanguage => AppLanguage.fromCode(state.languageCode);

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_localeKey);
    if (code != null) {
      state = AppLanguage.fromCode(code).locale;
    }
  }

  Future<void> setLanguage(AppLanguage language) async {
    state = language.locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, language.code);
  }
}
