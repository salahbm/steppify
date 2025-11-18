import 'package:flutter/material.dart';

class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({
    super.key,
    this.message,
  });

  final String? message;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      const CircularProgressIndicator(),
    ];

    if (message != null) {
      children.addAll([
        const SizedBox(height: 12),
        Text(
          message!,
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ]);
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }
}
