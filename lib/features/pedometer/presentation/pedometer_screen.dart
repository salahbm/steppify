import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../domain/pedometer_entity.dart';
import '../widgets/creative_card.dart';
import '../widgets/step_gauge.dart';
import 'pedometer_controller.dart';

class PedometerScreen extends ConsumerWidget {
  const PedometerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pedometerControllerProvider);
    final controller = ref.read(pedometerControllerProvider.notifier);
    final format = NumberFormat.decimalPattern();
    final theme = Theme.of(context);

    final gauge = StepGauge(
      progress: state.progress,
      steps: state.entity.totalSteps,
      goal: state.entity.goal,
    );

    final statsCard = _StatsCard(entity: state.entity);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pedometer'),
        actions: [
          IconButton(
            tooltip: 'Refresh quote',
            onPressed: controller.refreshQuote,
            icon: const Icon(Icons.auto_awesome),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: controller.refreshQuote,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 720;
            final content = [
              if (state.isLoading)
                const LinearProgressIndicator(minHeight: 2),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: isWide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: Center(child: gauge)),
                          const SizedBox(width: 32),
                          Expanded(child: statsCard),
                        ],
                      )
                    : Column(
                        children: [
                          gauge,
                          const SizedBox(height: 24),
                          statsCard,
                        ],
                      ),
              ),
              CreativeCard(
                title: 'Motivation boost',
                subtitle: state.entity.motivationalQuote,
                leading: AnimatedScale(
                  scale: state.entity.totalSteps > 0 ? 1 : 0.9,
                  duration: const Duration(milliseconds: 400),
                  child: const Icon(Icons.emoji_emotions, size: 48),
                ),
                trailing: Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
                onTap: controller.refreshQuote,
              ),
              const SizedBox(height: 16),
              SwitchListTile.adaptive(
                title: const Text('Background tracking'),
                subtitle: const Text(
                  'Keep counting steps even when the app is closed. '
                  'Ensure ACTIVITY_RECOGNITION / Motion & Fitness permissions are granted.',
                ),
                value: state.entity.backgroundTrackingEnabled,
                onChanged: (value) {
                  controller.toggleBackgroundTracking(value);
                },
              ),
              const SizedBox(height: 16),
              CreativeCard(
                title: 'Daily digest',
                subtitle:
                    'Total steps today: ${format.format(state.entity.totalSteps)}.\n'
                    'Last update: ${state.entity.lastUpdated?.toLocal().toString().substring(11, 16) ?? '—'}',
                leading: Icon(
                  Icons.timeline,
                  size: 36,
                  color: theme.colorScheme.onSecondaryContainer,
                ),
                trailing: FilledButton.tonal(
                  onPressed: state.entity.isTracking
                      ? controller.stopTracking
                      : controller.startTracking,
                  child: Text(state.entity.isTracking ? 'Pause' : 'Resume'),
                ),
              ),
              const SizedBox(height: 16),
              CreativeCard(
                title: 'Sync & Celebrate',
                subtitle:
                    'Plan to sync your steps with the cloud and trigger streak notifications. '
                    'Stay tuned for even smarter coaching!',
                leading: const Icon(Icons.cloud_sync, size: 42),
                // TODO(dev): Wire this card to the cloud sync module when available.
              ),
              if (state.hasError) ...[
                const SizedBox(height: 16),
                Text(
                  state.errorMessage ?? 'Something went wrong.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 48),
            ];

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: content,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.entity});

  final PedometerEntity entity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Live progress',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  entity.isTracking ? Icons.directions_walk : Icons.pause_circle,
                  color: theme.colorScheme.primary,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Text(
                  entity.isTracking ? 'Tracking' : 'Paused',
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              runSpacing: 12,
              children: [
                _StatBubble(
                  label: 'Goal',
                  value: entity.goal.toInt().toString(),
                ),
                _StatBubble(
                  label: 'Progress',
                  value: '${(entity.progress * 100).toStringAsFixed(0)}%',
                ),
                _StatBubble(
                  label: 'Updated',
                  value: entity.lastUpdated != null
                      ? TimeOfDay.fromDateTime(entity.lastUpdated!)
                          .format(context)
                      : '—',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBubble extends StatelessWidget {
  const _StatBubble({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 120,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.labelMedium),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
