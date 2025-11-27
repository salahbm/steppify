import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:steppify/injection_container.dart';
import 'package:steppify/config/config.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(themeProvider);
    final locale = Localizations.localeOf(context);
    final l = AppLocalizations.of(context).translate;

    return Scaffold(
      appBar: AppBar(
        title: Text(l('title')),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l('greeting'),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${l('language')}: ${locale.languageCode == 'en' ? l('locale_en') : l('locale_ko')}',
              ),
              const SizedBox(height: 12),
              Text(
                '${l('dark_mode')}: ${isDarkMode ? l('dark_mode') : l('light_mode')}',
              ),
              const SizedBox(height: 24),

              // Navigate to Pedometer Button
              ElevatedButton.icon(
                icon: const Icon(Icons.directions_walk),
                label: Text(l('go_to_pedometer')),
                onPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.stepTracker),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.directions_walk),
                label: Text('Minimal Pedometer'),
                onPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.pedometer),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
