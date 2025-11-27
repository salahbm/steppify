import 'package:flutter/material.dart';

/// Banner displaying current date and reset information
class DateInfoBanner extends StatelessWidget {
  final String currentDate;

  const DateInfoBanner({
    super.key,
    required this.currentDate,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today,
              color: Colors.blue,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                "Today: $currentDate | Resets at midnight",
                style: const TextStyle(fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
