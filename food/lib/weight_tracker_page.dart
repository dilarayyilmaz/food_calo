import 'package:flutter/material.dart';

class WeightTrackerPage extends StatelessWidget {
  const WeightTrackerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kilo Takibi'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text(
          'Kilo Takibi Sayfası Yakında!',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
