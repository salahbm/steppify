import 'package:flutter/material.dart';

class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final column = <Widget>[
      const SizedBox(
        width: 48,
        height: 48,
        child: CircularProgressIndicator(),
      ),
    ];

    if (message != null) {
      column.addAll([
        const SizedBox(height: 12),
        Text(message!, style: Theme.of(context).textTheme.bodyMedium),
      ]);
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: column,
      ),
    );
  }
}
