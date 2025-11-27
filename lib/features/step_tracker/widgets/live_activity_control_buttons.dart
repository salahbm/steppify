import 'package:flutter/material.dart';

/// Live Activity control buttons (iOS)
class LiveActivityControlButtons extends StatelessWidget {
  final bool isActive;
  final VoidCallback onStart;
  final VoidCallback onUpdate;
  final VoidCallback onEnd;

  const LiveActivityControlButtons({
    super.key,
    required this.isActive,
    required this.onStart,
    required this.onUpdate,
    required this.onEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton(
          onPressed: !isActive ? onStart : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
          child: const Text("Start Live Activity"),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: isActive ? onUpdate : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          child: const Text("Update Live Activity (Manual)"),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: isActive ? onEnd : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: const Text("Stop Live Activity"),
        ),
      ],
    );
  }
}
