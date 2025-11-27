import 'package:flutter/material.dart';

/// Start and Pause tracking control buttons
class TrackingControlButtons extends StatelessWidget {
  final bool isPaused;
  final VoidCallback onStart;
  final VoidCallback onPause;

  const TrackingControlButtons({
    super.key,
    required this.isPaused,
    required this.onStart,
    required this.onPause,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: isPaused ? onStart : null,
            icon: const Icon(Icons.play_arrow),
            label: const Text("Start"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: !isPaused ? onPause : null,
            icon: const Icon(Icons.pause),
            label: const Text("Pause"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
