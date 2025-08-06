import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ADIM 1'DE GÜNCELLEDİĞİMİZ SINIF
class WaterLog {
  final int amount;
  final DateTime time;

  WaterLog({required this.amount, required this.time});

  Map<String, dynamic> toJson() => {
    'amount': amount,
    'time': Timestamp.fromDate(time),
  };

  factory WaterLog.fromJson(Map<String, dynamic> json) => WaterLog(
    amount: json['amount'] as int,
    time: (json['time'] as Timestamp).toDate(),
  );
}

class WaterTrackerPage extends StatefulWidget {
  const WaterTrackerPage({super.key});
  @override
  State<WaterTrackerPage> createState() => _WaterTrackerPageState();
}

class _WaterTrackerPageState extends State<WaterTrackerPage> {
  // --- Firebase Değişkenleri ---
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  User? _user;
  bool _isLoading = true;

  // --- State Değişkenleri ---
  int _dailyGoal = 2500; // Varsayılan hedef
  int _currentIntake = 0;
  final List<WaterLog> _waterLogHistory = [];
  final int _standardAmount = 250;

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
    if (_user != null) {
      _loadDailyDataFromFirebase();
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // --- FIREBASE İLE İLETİŞİM METOTLARI ---

  /// Günlük verileri Firebase'den yükler. Eğer gün değişmişse verileri sıfırlar.
  Future<void> _loadDailyDataFromFirebase() async {
    if (_user == null) return;

    final todayString = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final docRef = _firestore.collection('user_water_data').doc(_user!.uid);

    try {
      final docSnap = await docRef.get();
      if (docSnap.exists) {
        final data = docSnap.data()!;
        // Kullanıcının hedefini yükle, yoksa varsayılanı kullan
        _dailyGoal = data['dailyGoal'] ?? 2500;

        // En son kaydedilen gün bugün mü diye kontrol et
        if (data['lastUpdateDate'] == todayString) {
          final logData = List<Map<String, dynamic>>.from(
            data['dailyLogs'] ?? [],
          );
          _waterLogHistory.clear();
          _waterLogHistory.addAll(logData.map((e) => WaterLog.fromJson(e)));

          // Mevcut alımı yeniden hesapla
          _currentIntake = _waterLogHistory.fold(
            0,
            (sum, item) => sum + item.amount,
          );
        } else {
          // Gün değiştiyse, bugünün verilerini temizle
          _currentIntake = 0;
          _waterLogHistory.clear();
          // Firestore'daki log listesini de temizleyebiliriz
          await docRef.update({'dailyLogs': []});
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Su verileri yüklenemedi: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// İçilen suyu Firebase'e ve lokal duruma ekler.
  Future<void> _addWater(int amount) async {
    if (_user == null) return;

    final newLog = WaterLog(amount: amount, time: DateTime.now());
    final todayString = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // Önce lokal state'i güncelle (daha hızlı UI tepkisi için)
    setState(() {
      _currentIntake += amount;
      _waterLogHistory.insert(0, newLog);
    });

    // Sonra Firebase'i güncelle
    try {
      final docRef = _firestore.collection('user_water_data').doc(_user!.uid);
      await docRef.set({
        'lastUpdateDate': todayString,
        'dailyLogs': FieldValue.arrayUnion([newLog.toJson()]),
      }, SetOptions(merge: true));
    } catch (e) {
      // Hata durumunda UI'ı geri al ve kullanıcıyı bilgilendir
      setState(() {
        _currentIntake -= amount;
        _waterLogHistory.remove(newLog);
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Su eklenirken hata oluştu: $e')));
    }
  }

  /// Kullanıcının günlük hedefini günceller.
  Future<void> _updateGoalInFirebase(int newGoal) async {
    if (_user == null) return;

    // Lokal state'i güncelle
    setState(() {
      _dailyGoal = newGoal;
    });

    // Firebase'i güncelle
    try {
      final docRef = _firestore.collection('user_water_data').doc(_user!.uid);
      await docRef.set({'dailyGoal': newGoal}, SetOptions(merge: true));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hedef güncellenirken hata oluştu: $e')),
      );
    }
  }

  /// Hedef belirleme diyalogunu gösterir.
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
                Navigator.of(context).pop();
                if (newGoal != null && newGoal > 0) {
                  _updateGoalInFirebase(
                    newGoal,
                  ); // Firebase'i çağıran metodu kullan
                }
              },
            ),
          ],
        );
      },
    );
  }

  // --- BUILD METOTLARI (Çoğunlukla aynı, _isLoading eklendi) ---
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_user == null) {
      return const Center(
        child: Text("Verileri görmek için lütfen giriş yapın."),
      );
    }

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

  // Bu alt widget'lar lokal state'ten okuduğu için değiştirilmesine gerek yok.
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
                "Bugün İçtiklerin",
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
          if (totalGlasses > 0)
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12.0,
              runSpacing: 12.0,
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
