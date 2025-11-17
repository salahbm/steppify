// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get title => 'Steppify';

  @override
  String get greeting => 'Welcome to Steppify';

  @override
  String get settings => 'Settings';

  @override
  String get theme => 'Dark Theme';

  @override
  String get language => 'Language';
}
