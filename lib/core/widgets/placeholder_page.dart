import 'package:flutter/material.dart';

class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Steppify'),
      ),
      body: const Center(
        child: Text('Welcome to Steppify'),
      ),
    );
  }
}
