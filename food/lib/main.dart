import 'package:flutter/material.dart';
import 'cal_predictor.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calorie Predictor',

      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFF27A23)),

        useMaterial3: true,
      ),
      home: CalPredictor(),
    );
  }
}
