// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get title => '스텝피파이';

  @override
  String get greeting => '스텝피파이에 오신 것을 환영합니다';

  @override
  String get settings => '설정';

  @override
  String get dark_mode => '다크 모드';

  @override
  String get light_mode => '라이트 모드';

  @override
  String get language => '언어';

  @override
  String get locale_en => '영어';

  @override
  String get locale_ko => '한국어';

  @override
  String get go_to_pedometer => 'Pedometer로 이동';
}
