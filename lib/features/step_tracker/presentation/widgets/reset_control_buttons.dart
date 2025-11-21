import 'package:flutter/material.dart';

/// Reset session and day control buttons
class ResetControlButtons extends StatelessWidget {
  final VoidCallback onResetSession;
  final VoidCallback onResetDay;

  const ResetControlButtons({
    super.key,
    required this.onResetSession,
    required this.onResetDay,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onResetSession,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text(
              "Reset Session",
              style: TextStyle(fontSize: 13),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onResetDay,
            icon: const Icon(Icons.restart_alt, size: 18),
            label: const Text(
              "Reset Day",
              style: TextStyle(fontSize: 13),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade800,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
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
