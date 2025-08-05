import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'cal_predictor.dart';
import 'water_tracker_page.dart';
import 'weight_tracker_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      body: const Center(child: Text('Ayarlar Sayfası')),
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDE8D8),
      appBar: AppBar(
        title: Text(
          'Mamma Mia',
          style: GoogleFonts.pacifico(fontSize: 28, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFF27A23),
        elevation: 0,
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(20),
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        children: <Widget>[
          _buildFeatureCard(
            context: context,
            icon: Icons.calculate,
            title: 'Kalori Hesapla',
            page: CalPredictor(),
          ),

          _buildFeatureCard(
            context: context,
            icon: Icons.local_drink,
            title: 'Su Takibi',
            page: const WaterTrackerPage(),
          ),

          _buildFeatureCard(
            context: context,
            icon: Icons.monitor_weight_outlined,
            title: 'Kilo Takibi',
            page: const WeightTrackerPage(),
          ),

          _buildFeatureCard(
            context: context,
            icon: Icons.settings,
            title: 'Ayarlar',
            page: const SettingsPage(),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required Widget page,
  }) {
    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => page));
      },
      child: Card(
        color: Colors.white, 
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, size: 50, color: const Color(0xFFF27A23)),
            const SizedBox(height: 15),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
