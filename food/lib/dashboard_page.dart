import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Yönlendirilecek tüm sayfaları import et
import 'cal_predictor.dart';
import 'water_tracker_page.dart';
import 'weight_tracker_page.dart';

// Ayarlar için de basit bir yer tutucu sayfa oluşturalım
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
          // 1. Kalori Hesapla Kartı (Bu zaten doğruydu)
          _buildFeatureCard(
            context: context,
            icon: Icons.calculate,
            title: 'Kalori Hesapla',
            page: CalPredictor(),
          ),

          // 2. Su Takibi Kartı
          _buildFeatureCard(
            context: context,
            icon: Icons.local_drink,
            title: 'Su Takibi',
            // <<<--- DOĞRUSU: Hedef sayfa WaterTrackerPage olmalı ---<<<
            page: const WaterTrackerPage(),
          ),

          // 3. Kilo Takibi Kartı
          _buildFeatureCard(
            context: context,
            // <<<--- İKON DÜZELTMESİ: İkonu doğru olanla değiştirdim ---<<<
            icon: Icons.monitor_weight_outlined,
            title: 'Kilo Takibi',
            // <<<--- HATA BURADAYDI: Hedef sayfa CalPredictor() olarak kalmış ---<<<
            // <<<--- DOĞRUSU: Hedef sayfa WeightTrackerPage() olmalı ---<<<
            page: const WeightTrackerPage(),
          ),

          // 4. Ayarlar Kartı
          _buildFeatureCard(
            context: context,
            icon: Icons.settings,
            title: 'Ayarlar',
            // <<<--- DOĞRUSU: Hedef sayfa SettingsPage olmalı ---<<<
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
        color: Colors.white, // Kart rengini daha belirgin yapalım
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
