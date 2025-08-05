import 'dart:async'; 
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; 
import 'cal_predictor.dart'; 

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 2), _navigateToHome);
  }

  void _navigateToHome() {
    
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (BuildContext context) => CalPredictor()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF27A23), 
      body: Center(
        child: Text(
          'Mamma Mia',
          style: GoogleFonts.pacifico(
            fontSize: 50,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
