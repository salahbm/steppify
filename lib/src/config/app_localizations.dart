import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;
  late final Map<String, String> _localizedStrings;

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('ko'),
  ];

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static Future<AppLocalizations> load(Locale locale) async {
    Intl.defaultLocale = locale.languageCode;
    final localization = AppLocalizations(locale);
    final data = await rootBundle.loadString(_localePath(locale));
    final Map<String, dynamic> jsonMap = jsonDecode(data);
    localization._localizedStrings = jsonMap.entries
        .where((entry) => !entry.key.startsWith('@'))
        .map((entry) => MapEntry(entry.key, entry.value.toString()))
        .fold(<String, String>{}, (acc, entry) {
      acc[entry.key] = entry.value;
      return acc;
    });
    return localization;
  }

  static String _localePath(Locale locale) =>
      'lib/src/l10n/intl_${locale.languageCode}.arb';

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  String translate(String key) => _localizedStrings[key] ?? key;

  String get title => translate('title');
  String get greeting => translate('greeting');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales
        .any((supported) => supported.languageCode == locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) =>
      AppLocalizations.load(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
