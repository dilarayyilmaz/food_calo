import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';


// Veri Modeli
class WaterLog {
  final int amount;
  final DateTime time;

  WaterLog({required this.amount, required this.time});
}

class WaterTrackerPage extends StatefulWidget {
  const WaterTrackerPage({super.key});

  @override
  State<WaterTrackerPage> createState() => _WaterTrackerPageState();
}

class _WaterTrackerPageState extends State<WaterTrackerPage> {
  int _dailyGoal = 2500;
  int _currentIntake = 0;
  final List<WaterLog> _waterLogHistory = [];
  final int _standardAmount = 250;

  void _addWater(int amount) {
    setState(() {
      _currentIntake += amount;
      _waterLogHistory.insert(
        0,
        WaterLog(amount: amount, time: DateTime.now()),
      );
    });
  }

  // <<<--- HEDEF AYARLAMA DİYALOG KUTUSU FONKSİYONU ---<<<
  Future<void> _showGoalSettingDialog() async {
    final _goalController = TextEditingController(text: _dailyGoal.toString());

    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFFEF7F1),
          title: const Text('Günlük Hedef Belirle'),
          content: TextField(
            controller: _goalController,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Hedef (ml)',
              suffixText: 'ml',
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('İptal'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Kaydet'),
              onPressed: () {
                final newGoal = int.tryParse(_goalController.text);
                if (newGoal != null && newGoal > 0) {
                  setState(() {
                    _dailyGoal = newGoal; // Hedefi güncelle
                  });
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFEF7F1),
      child: SingleChildScrollView(
        child: Column(children: [_buildHeader(), _buildHistorySection()]),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 0),
      child: Column(
        children: [
          _buildMascotAndTitle(),
          const SizedBox(height: 24),
          _buildProgressIndicator(),
        ],
      ),
    );
  }

  Widget _buildMascotAndTitle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Image.asset(
          'assets/images/water_drop.png',
          height: 60,
          color: Colors.grey.shade600,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(
              Icons.water_drop_outlined,
              size: 60,
              color: Colors.grey,
            );
          },
        ),
        const SizedBox(width: 16),
        const Text(
          "Su Takibi",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0D47A1),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    double progress = _dailyGoal > 0 ? _currentIntake / _dailyGoal : 0;
    if (progress > 1.0) progress = 1.0;

    // <<<--- DEĞİŞİKLİK: GestureDetector ile sarmaladık ---<<<
    return GestureDetector(
      // Hedefi ayarlamak için tüm alana tıklanabilirlik ekliyoruz.
      onTap: _showGoalSettingDialog,
      child: SizedBox(
        height: 200,
        width: 200,
        child: Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.none,
          children: [
            CircularProgressIndicator(
              value: 1,
              strokeWidth: 20,
              backgroundColor: const Color(0xFFF27A23).withOpacity(0.3),
            ),
            ShaderMask(
              shaderCallback: (rect) {
                return const SweepGradient(
                  startAngle: -1.57,
                  colors: [Colors.lightBlueAccent, Colors.blue],
                ).createShader(rect);
              },
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 20,
                backgroundColor: Colors.transparent,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$_currentIntake / $_dailyGoal',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 28.0,
                      color: Color(0xFF0D47A1),
                    ),
                  ),
                  const Text(
                    'ml',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: -15,
              left: 0,
              right: 0,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: GestureDetector(
                  onTap: () => _addWater(_standardAmount),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.local_drink_outlined,
                          color: Colors.blue.shade700,
                          size: 28,
                        ),
                        Text(
                          '${_standardAmount}ml',
                          style: TextStyle(
                            color: Colors.blue.shade900,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistorySection() {
    int glassesDrunk = (_currentIntake / _standardAmount).floor();
    // <<<--- DEĞİŞİKLİK: Toplam bardak sayısı artık güncel hedefe göre hesaplanıyor ---<<<
    int totalGlasses = (_dailyGoal > 0)
        ? (_dailyGoal / _standardAmount).ceil()
        : 0;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Today's Drinks",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
              Text(
                '$glassesDrunk / $totalGlasses bardak',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 16.0,
            runSpacing: 16.0,
            children: List.generate(totalGlasses, (index) {
              bool isDrunk = index < glassesDrunk;
              return Icon(
                isDrunk ? Icons.local_drink : Icons.local_drink_outlined,
                size: 40,
                color: isDrunk ? Colors.blue : Colors.grey.shade300,
              );
            }),
          ),
        ],
      ),
    );
  }
}
