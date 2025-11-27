import 'package:flutter/material.dart';

/// Status indicator with colored dot and text
class StatusIndicator extends StatelessWidget {
  final String status;
  final Color color;

  const StatusIndicator({
    super.key,
    required this.status,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(width: 8),
        Text('Status: $status'),
      ],
    );
  }
}
