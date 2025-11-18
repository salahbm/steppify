import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

    final gauge = StepGauge(
      progress: state.entity.progress,
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
      body: Center(
        child: state.isLoading
            ? const CircularProgressIndicator()
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  gauge,
                  statsCard,
                  CreativeCard(
                    title: 'Motivation',
                    subtitle: state.entity.motivationalQuote,
                    leading: const Icon(Icons.directions_walk, size: 48),
                    onTap: controller.refreshQuote,
                  ),
                ],
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
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text('Live Progress', style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            Text('Steps: ${entity.totalSteps}'),
            Text('Goal: ${entity.goal.toInt()}'),
            Text(
              'Updated at: ${entity.lastUpdated?.toLocal().toString() ?? '—'}',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
