import 'package:flutter/material.dart';

/// Helper functions for status colors and icons
class StatusHelpers {
  /// Get color for a given status
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'walking':
        return Colors.green;
      case 'stationary':
      case 'stopped':
        return Colors.orange;
      case 'active':
        return Colors.blue;
      case 'error':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// Get icon for a given status
  static IconData getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'walking':
        return Icons.directions_walk;
      case 'stationary':
      case 'stopped':
        return Icons.pause_circle_outline;
      case 'active':
        return Icons.check_circle;
      case 'error':
        return Icons.error_outline;
      default:
        return Icons.help_outline;
    }
  }
}
