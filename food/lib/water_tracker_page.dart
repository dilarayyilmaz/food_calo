import 'package:flutter/material.dart';

class WaterTrackerPage extends StatelessWidget {
  const WaterTrackerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Su Takibi'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text(
          'Su Takibi Sayfası Yakında!',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
