import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'pedometer_controller.dart';
import '../data/pedometer_state.dart';
import '../../step_tracker/data/live_activity_service.dart';
import '../../step_tracker/data/steps_live_model.dart';

class PedometerScreen extends ConsumerWidget {
  const PedometerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pedometerControllerProvider);
    final controller = ref.read(pedometerControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Step Tracker'),
        bottom: state.isLoading
            ? const PreferredSize(
                preferredSize: Size.fromHeight(4),
                child: LinearProgressIndicator(minHeight: 4),
              )
            : null,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _buildBody(context, state, controller),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    PedometerState state,
    PedometerController controller,
  ) {
    if (!state.isSupported) {
      return _InfoMessage(
        icon: Icons.watch_off_outlined,
        title: 'Step tracking unavailable',
        message:
            state.errorMessage ??
            'Your device does not expose any step data that we can read.',
      );
    }

    if (!state.hasPermission) {
      return _InfoMessage(
        icon: Icons.directions_walk,
        title: 'Enable motion tracking',
        message:
            state.errorMessage ??
            'Grant motion and fitness permissions so we can read today\'s steps.',
        actionLabel: 'Allow access',
        onAction: controller.retry,
      );
    }

    return _TrackingView(state: state, onRefresh: () => controller.retry());
  }
}

class _TrackingView extends StatefulWidget {
  const _TrackingView({required this.state, required this.onRefresh});

  final PedometerState state;
  final VoidCallback onRefresh;

  @override
  State<_TrackingView> createState() => _TrackingViewState();
}

class _TrackingViewState extends State<_TrackingView> {
  final LiveActivityService _liveActivityService = LiveActivityService();
  bool _liveActivityActive = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lastUpdated = widget.state.lastUpdated == null
        ? 'Waiting for data from the pedometer'
        : 'Updated at ${TimeOfDay.fromDateTime(widget.state.lastUpdated!).format(context)}';

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "Since app launch",
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              '${widget.state.sinceAppLaunch}',
              key: ValueKey(widget.state.sinceAppLaunch),
              textAlign: TextAlign.center,
              style: theme.textTheme.displayLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              '${widget.state.totalSteps} today',
              key: ValueKey(widget.state.totalSteps),
              textAlign: TextAlign.center,
              style: theme.textTheme.displayLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            lastUpdated,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: widget.state.isLoading ? null : widget.onRefresh,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh now'),
          ),
          const SizedBox(height: 24),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: const [
                _StatusTile(
                  icon: Icons.phone_android,
                  title: 'Device support',
                  message: 'This device can share step data with Steppify.',
                ),
                Divider(height: 1),
                _StatusTile(
                  icon: Icons.security,
                  title: 'Motion permission',
                  message:
                      'Permission granted — tracking continues in the background.',
                ),
                Divider(height: 1),
                _StatusTile(
                  icon: Icons.autorenew,
                  title: 'Live updates',
                  message:
                      'Steps update automatically as we listen to the native pedometer.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Live Activity Controls
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton(
                onPressed: !_liveActivityActive ? _startLiveActivity : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text("Start Live Activity"),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _liveActivityActive ? _updateLiveActivity : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text("Update Live Activity (Manual)"),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _liveActivityActive ? _endLiveActivity : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text("Stop Live Activity"),
              ),
            ],
          ),
          if (widget.state.errorMessage != null) ...[
            const SizedBox(height: 24),
            Text(
              widget.state.errorMessage!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _startLiveActivity() async {
    if (_liveActivityActive) return;

    try {
      await _liveActivityService.startLiveActivity(
        data: StepLiveActivityModel(
          todaySteps: widget.state.totalSteps,
          sinceOpenSteps: widget.state.sinceAppLaunch,
          sinceBootSteps: 0, // Android doesn't track since boot
          status: 'active',
        ),
      );
      setState(() => _liveActivityActive = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start Live Activity: $e')),
        );
      }
    }
  }

  Future<void> _updateLiveActivity() async {
    if (!_liveActivityActive) return;

    try {
      await _liveActivityService.updateLiveActivity(
        data: StepLiveActivityModel(
          todaySteps: widget.state.totalSteps,
          sinceOpenSteps: widget.state.sinceAppLaunch,
          sinceBootSteps: 0,
          status: 'manual',
        ),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Live Activity updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e')),
        );
      }
    }
  }

  Future<void> _endLiveActivity() async {
    if (!_liveActivityActive) return;

    try {
      await _liveActivityService.endLiveActivity();
      setState(() => _liveActivityActive = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Live Activity stopped')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to stop: $e')),
        );
      }
    }
  }
}

class _InfoMessage extends StatelessWidget {
  const _InfoMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 72, color: theme.colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            title,
            style: theme.textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: 24),
            FilledButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

class _StatusTile extends StatelessWidget {
  const _StatusTile({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(title),
      subtitle: Text(message),
    );
  }
}
