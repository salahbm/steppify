import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../injection_container.dart';
import '../../../config/config.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(themeProvider);
    final currentLocale = ref.watch(localeProvider);
    final trackLocation = ref.watch(locationTrackingProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).translate('settings')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ListTile(
              title: Text(AppLocalizations.of(context).translate('theme')),
              trailing: Switch(
                value: isDarkMode,
                onChanged: (_) =>
                    ref.read(themeProvider.notifier).toggleTheme(),
              ),
            ),
            const Divider(),
            ListTile(
              title: Text(AppLocalizations.of(context).translate('language')),
              trailing: DropdownButton<Locale>(
                value: currentLocale,
                items: const [
                  DropdownMenuItem(value: Locale('en'), child: Text('English')),
                  DropdownMenuItem(value: Locale('ko'), child: Text('한국어')),
                ],
                onChanged: (locale) {
                  if (locale != null) {
                    ref.read(localeProvider.notifier).updateLocale(locale);
                  }
                },
              ),
            ),
            const Divider(),
            ListTile(
              title: const Text('Location Tracking'),
              trailing: Switch(
                value: trackLocation,
                onChanged: (_) =>
                    ref.read(locationTrackingProvider.notifier).toggle(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
