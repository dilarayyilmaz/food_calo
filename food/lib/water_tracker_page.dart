import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

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
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
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
                    _dailyGoal = newGoal;
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
    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD),
      appBar: AppBar(
        title: Text(
          'Mamma Mia',
          style: GoogleFonts.pacifico(fontSize: 28, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFF27A23),
        foregroundColor: Colors.white,
        elevation: 0,

        actions: [
          IconButton(
            icon: const Icon(Icons.track_changes), 
            tooltip: 'Hedefi Değiştir', 
            onPressed:
                _showGoalSettingDialog, 
          ),
        ],
        
      ),
      body: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildHistorySection(),
        ],
      ),
    );
  }


  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16.0),
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
            return Icon(
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

    return SizedBox(
      height: 200,
      width: 200,
      child: Stack(
        fit: StackFit.expand,
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
                endAngle: 3.14 * 2,
                colors: [Colors.lightBlueAccent, Colors.blue],
                stops: [0.0, 0.7],
                transform: GradientRotation(-1.57),
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
          Align(
            alignment: const Alignment(0.0, 1.4),
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
        ],
      ),
    );
  }

  Widget _buildHistorySection() {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(top: 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 15)],
        ),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Text(
                "Today's History",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
            ),
            Expanded(
              child: _waterLogHistory.isEmpty
                  ? const Center(child: Text('Henüz su içmediniz.'))
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _waterLogHistory.length,
                      itemBuilder: (context, index) {
                        final log = _waterLogHistory[index];
                        return ListTile(
                          leading: const Icon(
                            Icons.local_drink,
                            color: Colors.blue,
                          ),
                          title: Text(
                            '${log.amount} ml',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          trailing: Text(
                            DateFormat.jm().format(log.time),
                            style: const TextStyle(color: Colors.grey),
                          ),
                        );
                      },
                      separatorBuilder: (context, index) =>
                          const Divider(indent: 16, endIndent: 16),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
