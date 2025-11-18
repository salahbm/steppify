import 'package:flutter/material.dart';

class StepGauge extends StatelessWidget {
  const StepGauge({
    super.key,
    required this.progress,
    required this.steps,
    required this.goal,
  });

  final double progress;
  final int steps;
  final double goal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final dimension = constraints.biggest.shortestSide == double.infinity
            ? 240.0
            : constraints.biggest.shortestSide;
        return SizedBox(
          width: dimension,
          height: dimension,
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 600),
            tween: Tween<double>(begin: 0, end: progress.clamp(0, 1)),
            builder: (context, animatedValue, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: SweepGradient(
                        colors: [
                          theme.colorScheme.primary.withOpacity(0.2),
                          theme.colorScheme.primary,
                        ],
                        stops: const [0.25, 1],
                      ),
                    ),
                  ),
                  SizedBox(
                    width: dimension * 0.95,
                    height: dimension * 0.95,
                    child: CircularProgressIndicator(
                      value: animatedValue,
                      strokeWidth: 14,
                      backgroundColor: theme.colorScheme.surfaceVariant,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$steps',
                            style: theme.textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'of ${goal.toInt()} steps',
                            style: theme.textTheme.labelLarge,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
