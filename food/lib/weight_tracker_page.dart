import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import 'package:confetti/confetti.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ADIM 2'DE GÜNCELLEDİĞİMİZ SINIF
class WeightEntry {
  final double weight;
  final DateTime date;

  WeightEntry({required this.weight, required this.date});

  Map<String, dynamic> toJson() => {
    'weight': weight,
    'date': Timestamp.fromDate(date),
  };

  factory WeightEntry.fromJson(Map<String, dynamic> json) => WeightEntry(
    weight: (json['weight'] as num).toDouble(),
    date: (json['date'] as Timestamp).toDate(),
  );
}

class WeightTrackerPage extends StatefulWidget {
  const WeightTrackerPage({super.key});

  @override
  State<WeightTrackerPage> createState() => _WeightTrackerPageState();
}

class _WeightTrackerPageState extends State<WeightTrackerPage> {
  // --- Firebase Değişkenleri ---
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  User? _user;
  bool _isLoading =
      true; // Veri yüklenirken gösterilecek loading indicator için

  // --- State Değişkenleri (Lokal) ---
  double? _targetWeight;
  final List<WeightEntry> _weightHistory = [];
  late ConfettiController _confettiController;

  // --- Getter'lar (Değişmedi) ---
  double get _currentWeight =>
      _weightHistory.isEmpty ? 0.0 : _weightHistory.last.weight;
  double get _startingWeight =>
      _weightHistory.isEmpty ? 0.0 : _weightHistory.first.weight;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 1),
    );
    _user = _auth.currentUser;
    if (_user != null) {
      _loadUserDataFromFirebase();
    } else {
      // Kullanıcı giriş yapmamışsa, yüklemeyi durdur ve boş ekran göster
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  // --- FIREBASE İLE İLETİŞİM Kuran Metotlar ---

  Future<void> _loadUserDataFromFirebase() async {
    if (_user == null) return;
    try {
      final docRef = _firestore.collection('user_weight_data').doc(_user!.uid);
      final docSnap = await docRef.get();

      if (docSnap.exists) {
        final data = docSnap.data()!;
        _targetWeight = (data['targetWeight'] as num?)?.toDouble();

        // Tarihe göre sıralanmış bir liste elde etmek için
        final historyData = List<Map<String, dynamic>>.from(
          data['weightHistory'] ?? [],
        );
        _weightHistory.clear();
        _weightHistory.addAll(historyData.map((e) => WeightEntry.fromJson(e)));
        _weightHistory.sort((a, b) => a.date.compareTo(b.date));
      }
    } catch (e) {
      // Hata durumunda kullanıcıya bilgi ver
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Veriler yüklenirken hata oluştu: $e')),
      );
    } finally {
      // Her durumda yüklemeyi bitir ve ekranı güncelle
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateTargetWeightInFirebase(double newTarget) async {
    if (_user == null) return;
    final docRef = _firestore.collection('user_weight_data').doc(_user!.uid);
    await docRef.set({'targetWeight': newTarget}, SetOptions(merge: true));
  }

  Future<void> _addWeightEntryToFirebase(WeightEntry newEntry) async {
    if (_user == null) return;
    final docRef = _firestore.collection('user_weight_data').doc(_user!.uid);
    // FieldValue.arrayUnion, mevcut listeye yeni bir eleman ekler.
    await docRef.set({
      'weightHistory': FieldValue.arrayUnion([newEntry.toJson()]),
    }, SetOptions(merge: true));
  }

  // --- UI METOTLARI (Artık Firebase'i çağırıyorlar) ---

  Future<void> _showEditDialog({bool isEditingTarget = false}) async {
    final controller = TextEditingController(
      text: isEditingTarget
          ? (_targetWeight?.toString() ?? '')
          : (_currentWeight > 0 ? _currentWeight.toString() : ''),
    );

    return showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFFEF7F1),
          title: Text(
            isEditingTarget ? 'Hedef Kilo Belirle' : 'Kilonuzu Girin',
          ),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Kilo (kg)'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            TextButton(
              onPressed: () async {
                // asenkron yaptık
                final value = double.tryParse(controller.text);
                Navigator.pop(context); // Dialog'u hemen kapat

                if (value != null && value > 0) {
                  setState(() {
                    _isLoading = true;
                  }); // Yükleme animasyonu başlat

                  try {
                    if (isEditingTarget) {
                      await _updateTargetWeightInFirebase(value);
                      setState(() {
                        _targetWeight = value;
                      });
                    } else {
                      final newEntry = WeightEntry(
                        weight: value,
                        date: DateTime.now(),
                      );
                      await _addWeightEntryToFirebase(newEntry);
                      setState(() {
                        _weightHistory.add(newEntry);
                      });

                      if (_targetWeight == null) {
                        Future.delayed(
                          const Duration(milliseconds: 300),
                          () => _showEditDialog(isEditingTarget: true),
                        );
                      }
                    }
                    _checkIfGoalReached(); // Hedef kontrolünü yap
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Veri kaydedilirken hata oluştu: $e'),
                      ),
                    );
                  } finally {
                    setState(() {
                      _isLoading = false;
                    }); // Yüklemeyi bitir
                  }
                }
              },
              child: const Text('Kaydet'),
            ),
          ],
        );
      },
    );
  }

  // --- Build Metodu ve Alt Widget'lar (Çoğunlukla aynı, _isLoading eklendi) ---

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Kullanıcı giriş yapmadıysa veya bir sorun varsa
    if (_user == null) {
      return const Center(
        child: Text("Verileri görmek için lütfen giriş yapın."),
      );
    }

    return Container(
      color: const Color(0xFFFEF7F1),
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          _weightHistory.isEmpty ? _buildEmptyState() : _buildDataState(),
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [
              Colors.green,
              Colors.blue,
              Colors.pink,
              Colors.orange,
              Colors.purple,
            ],
          ),
        ],
      ),
    );
  }

  // _buildEmptyState, _buildDataState, _buildWeightCards ve diğer UI metotları
  // HİÇBİR DEĞİŞİKLİK GEREKTİRMEZ. Onları olduğu gibi bırakabilirsiniz.
  // ... (Önceki kodunuzdaki tüm _build... metotlarını buraya kopyalayın) ...
  // ...
  // ...

  // Buraya önceki kodunuzda bulunan tüm _build... metotlarını kopyalayın
  // Örneğin: _buildEmptyState, _buildDataState, _buildWeightCards,
  // _buildClickableCard, _buildSummaryInfo, _buildGraph
  // Bu metotlarda hiçbir değişiklik yapmanıza gerek yok.

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.scale_outlined, size: 100, color: Colors.grey[400]),
            const SizedBox(height: 20),
            const Text(
              'Kilo Takibine Başlayın',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Başlamak için mevcut kilonuzu ekleyin.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () => _showEditDialog(isEditingTarget: false),
              icon: const Icon(Icons.add),
              label: const Text('İlk Kilonu Ekle'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF27A23),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataState() {
    final double lostWeight = _startingWeight > 0
        ? _startingWeight - _currentWeight
        : 0.0;
    final double remainingWeight = (_currentWeight > 0 && _targetWeight != null)
        ? _currentWeight - _targetWeight!
        : 0.0;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          _buildWeightCards(),
          const SizedBox(height: 20),
          _buildSummaryInfo(lostWeight, remainingWeight),
          const SizedBox(height: 30),
          _buildGraph(),
        ],
      ),
    );
  }

  Widget _buildWeightCards() {
    return Row(
      children: [
        Expanded(
          child: _buildClickableCard(
            title: 'Güncel Ağırlık',
            valueText: '${_currentWeight.toStringAsFixed(1)} kg',
            color: Colors.white,
            onTap: () => _showEditDialog(isEditingTarget: false),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: _buildClickableCard(
            title: 'Hedef Ağırlık',
            valueText: _targetWeight != null
                ? '${_targetWeight!.toStringAsFixed(1)} kg'
                : 'Belirle',
            color: Colors.white,
            onTap: () => _showEditDialog(isEditingTarget: true),
          ),
        ),
      ],
    );
  }

  Widget _buildClickableCard({
    required String title,
    required String valueText,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
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
          children: [
            Text(
              title,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              valueText,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFFF27A23),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryInfo(double lost, double remaining) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: [
              const Text('Kayıp', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 4),
              Text(
                '${lost.toStringAsFixed(1)} kg',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          Column(
            children: [
              const Text('Kalan', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 4),
              Text(
                '${remaining.toStringAsFixed(1)} kg',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGraph() {
    if (_weightHistory.length < 2) {
      return const SizedBox(
        height: 300,
        child: Center(
          child: Text('Grafiği görmek için en az 2 kilo kaydı gerekir.'),
        ),
      );
    }

    final allWeights = _weightHistory.map((e) => e.weight).toList();
    if (_targetWeight != null) allWeights.add(_targetWeight!);
    final double maxY = allWeights.isNotEmpty
        ? allWeights.reduce(max) + 5
        : 100;
    final double minY = allWeights.isNotEmpty ? allWeights.reduce(min) - 5 : 0;

    final firstDate = _weightHistory.first.date;
    final lastDate = _weightHistory.last.date;
    final timeSpan = lastDate.difference(firstDate).inMilliseconds;
    final double interval = timeSpan > 0
        ? timeSpan / 4
        : const Duration(days: 1).inMilliseconds.toDouble();

    List<FlSpot> spots = _weightHistory
        .map(
          (entry) => FlSpot(
            entry.date.millisecondsSinceEpoch.toDouble(),
            entry.weight,
          ),
        )
        .toList();

    return SizedBox(
      height: 300,
      child: LineChart(
        LineChartData(
          maxY: maxY,
          minY: minY,
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() == meta.max.toInt() ||
                      value.toInt() == meta.min.toInt()) {
                    return Text(
                      '${value.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 12),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: interval,
                getTitlesWidget: (value, meta) {
                  DateTime date = DateTime.fromMillisecondsSinceEpoch(
                    value.toInt(),
                  );
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      DateFormat('d MMM').format(date),
                      style: const TextStyle(fontSize: 12),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              gradient: const LinearGradient(
                colors: [Color(0xFFF27A23), Colors.orangeAccent],
              ),
              barWidth: 4,
              dotData: FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFF27A23).withOpacity(0.4),
                    const Color(0xFFF27A23).withOpacity(0.05),
                  ],
                ),
              ),
            ),
          ],
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              if (_targetWeight != null)
                HorizontalLine(
                  y: _targetWeight!,
                  color: Colors.blueAccent.withOpacity(0.5),
                  strokeWidth: 2,
                  dashArray: [5, 5],
                  label: HorizontalLineLabel(
                    show: true,
                    alignment: Alignment.bottomRight,
                    padding: const EdgeInsets.only(right: 5, bottom: 2),
                    style: TextStyle(
                      color: Colors.blueAccent[700],
                      fontWeight: FontWeight.bold,
                    ),
                    labelResolver: (line) =>
                        'Hedef: ${line.y.toStringAsFixed(1)}',
                  ),
                ),
            ],
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (spot) => Colors.black.withOpacity(0.8),
              getTooltipItems: (spots) => spots.map((spot) {
                final date = DateTime.fromMillisecondsSinceEpoch(
                  spot.x.toInt(),
                );
                return LineTooltipItem(
                  '${spot.y.toStringAsFixed(1)} kg\n${DateFormat('d MMMM').format(date)}',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  void _checkIfGoalReached() {
    if (_targetWeight != null &&
        _currentWeight > 0 &&
        _currentWeight <= _targetWeight!) {
      _confettiController.play();
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('🎉 Tebrikler! 🎉'),
          content: const Text('Hedef kilona ulaştın! Harika bir iş çıkardın.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Harika!'),
            ),
          ],
        ),
      );
    }
  }
}
