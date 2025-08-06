import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

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

  Future<void> _showGoalSettingDialog() async {
    final _goalController = TextEditingController(text: _dailyGoal.toString());
    return showDialog<void>(
      context: context,
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
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('İptal'),
            ),
            TextButton(
              child: const Text('Kaydet'),
              onPressed: () {
                final newGoal = int.tryParse(_goalController.text);
                if (newGoal != null && newGoal > 0) {
                  setState(() => _dailyGoal = newGoal);
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
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 16.0),
          child: Column(
            children: [
              _buildProgressIndicator(),
              const SizedBox(height: 40),
              _buildHistorySection(),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildProgressIndicator() {
    double percent = _dailyGoal > 0 ? _currentIntake / _dailyGoal : 0;
    if (percent > 1.0) percent = 1.0;

    return GestureDetector(
      onTap: _showGoalSettingDialog,
      child: CircularPercentIndicator(
        radius: 100.0,
        lineWidth: 15.0,
        percent: percent,
        animation: true,
        animationDuration: 800,
        center: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${(percent * 100).toStringAsFixed(0)} %',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 48.0,
                color: Color(0xFF3D5AFE),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$_currentIntake / $_dailyGoal ml',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
        circularStrokeCap: CircularStrokeCap.round,
        backgroundColor: Colors.deepPurple.withOpacity(0.15),
        progressColor: const Color(0xFF651FFF),
      ),
    );
  }

  Widget _buildHistorySection() {
    int glassesDrunk = (_currentIntake / _standardAmount).floor();
    int totalGlasses = (_dailyGoal > 0)
        ? (_dailyGoal / _standardAmount).ceil()
        : 0;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
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
          Center(
            child: ElevatedButton.icon(
              onPressed: () => _addWater(_standardAmount),
              icon: const Icon(Icons.add),
              label: Text('$_standardAmount ml Ekle'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF27A23),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 15,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.center, 
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
