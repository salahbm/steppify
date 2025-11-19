import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/config.dart';
import '../injection_container.dart';

class SteppifyApp extends ConsumerWidget {
  const SteppifyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final environment = ref.watch(environmentProvider);
    final isDarkMode = ref.watch(themeProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp(
      title: environment.appName,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      debugShowCheckedModeBanner: false,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      onGenerateRoute: AppRoutes.onGenerateRoute,
      initialRoute: AppRoutes.home,
      localeResolutionCallback: (deviceLocale, supportedLocales) {
        if (deviceLocale == null) return supportedLocales.first;
        return supportedLocales.firstWhere(
          (locale) => locale.languageCode == deviceLocale.languageCode,
          orElse: () => supportedLocales.first,
        );
      },
    );
  }
}
