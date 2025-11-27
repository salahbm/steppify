import 'package:flutter/material.dart';

/// Activity logs viewer widget
class ActivityLogViewer extends StatelessWidget {
  final List<String> logs;

  const ActivityLogViewer({
    super.key,
    required this.logs,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Activity Logs",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: logs.isEmpty
                  ? const Center(
                      child: Text(
                        "No logs yet",
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      reverse: true,
                      itemCount: logs.length,
                      itemBuilder: (_, i) {
                        final reversedIndex = logs.length - 1 - i;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            logs[reversedIndex],
                            style: const TextStyle(
                              fontSize: 11,
                              fontFamily: 'monospace',
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
