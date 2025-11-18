import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/step_gauge.dart';
import 'pedometer_controller.dart';
import 'pedometer_state.dart';

class PedometerScreen extends ConsumerWidget {
  const PedometerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pedometerControllerProvider);
    final controller = ref.read(pedometerControllerProvider.notifier);
    final canRefresh =
        state.isSupported && state.hasPermission && !state.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pedometer'),
        actions: [
          IconButton(
            tooltip: 'Refresh today\'s steps',
            onPressed: canRefresh ? controller.refreshSteps : null,
            icon: const Icon(Icons.refresh),
          ),
        ],
        bottom: state.isLoading
            ? const PreferredSize(
                preferredSize: Size.fromHeight(4),
                child: LinearProgressIndicator(minHeight: 4),
              )
            : null,
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: _buildBody(context, state, controller, canRefresh),
      ),
      floatingActionButton:
          state.errorMessage != null && state.hasPermission && canRefresh
              ? FloatingActionButton.extended(
                  onPressed: controller.refreshSteps,
                  icon: const Icon(Icons.restart_alt),
                  label: const Text('Retry'),
                )
              : null,
    );
  }

  Widget _buildBody(
    BuildContext context,
    PedometerState state,
    PedometerController controller,
    bool canRefresh,
  ) {
    if (!state.isSupported) {
      return _ErrorView(
        icon: Icons.directions_walk_outlined,
        message:
            state.errorMessage ?? 'This platform does not support step tracking.',
      );
    }

    if (!state.hasPermission) {
      return _ErrorView(
        icon: Icons.lock_outline,
        message: state.errorMessage ??
            'We need motion permissions before we can show your steps.',
        actionLabel: 'Grant permission',
        onAction: controller.requestPermission,
      );
    }

    if (state.isLoading && state.totalSteps == 0) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: canRefresh ? controller.refreshSteps : () async {},
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: canRefresh ? controller.refreshSteps : null,
                  child: AbsorbPointer(
                    absorbing: !canRefresh,
                    child: StepGauge(
                      progress: state.progress,
                      steps: state.totalSteps,
                      goal: state.goal.toDouble(),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                _StatsCard(state: state),
                if (state.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      state.errorMessage!,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Theme.of(context).colorScheme.error),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.state});

  final PedometerState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lastUpdated = state.lastUpdated == null
        ? 'Waiting for data'
        : 'Updated at ${TimeOfDay.fromDateTime(state.lastUpdated!).format(context)}';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Today\'s steps', style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${state.totalSteps}',
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    )),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Daily goal: ${state.goal}'),
                    Text(lastUpdated, style: theme.textTheme.bodySmall),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Tap the gauge or pull down to refresh once permissions are granted.',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              message,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null)
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: ElevatedButton(
                  onPressed: onAction,
                  child: Text(actionLabel!),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
