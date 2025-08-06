import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';

import 'cal_predictor.dart';
import 'water_tracker_page.dart';
import 'weight_tracker_page.dart';
import 'settings_page.dart';
import 'manual_entry_page.dart';
import 'recipe_page.dart';

class FoodItem {
  final String id;
  final String name;
  final int calories;
  final double carbs;
  final double protein;
  final double fat;

  FoodItem({
    required this.id,
    required this.name,
    required this.calories,
    required this.carbs,
    required this.protein,
    required this.fat,
  });

  factory FoodItem.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return FoodItem(
      id: doc.id,
      name: data['name'] ?? '',
      calories: (data['calories'] as num?)?.toInt() ?? 0,
      carbs: (data['carbs'] as num?)?.toDouble() ?? 0.0,
      protein: (data['protein'] as num?)?.toDouble() ?? 0.0,
      fat: (data['fat'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;
  DateTime _selectedDate = DateTime.now();

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _navigateToSettings() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const SettingsPage()),
    );
    if (result == true && mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      DashboardContent(
        key: ValueKey(
          _selectedDate.toString(),
        ), 
        selectedDate: _selectedDate,
        onDateChange: (newDate) => setState(() => _selectedDate = newDate),
      ),
      const WaterTrackerPage(),
      const WeightTrackerPage(),
      const RecipePage(), 
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Mamma Mia',
          style: GoogleFonts.pacifico(
            color: const Color(0xFFF27A23),
            fontSize: 28,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.grey),
            onPressed: _navigateToSettings,
            tooltip: 'Ayarlar',
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.grey),
            onPressed: () async => await FirebaseAuth.instance.signOut(),
            tooltip: 'Çıkış Yap',
          ),
        ],
      ),
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Ana Sayfa'),
          BottomNavigationBarItem(icon: Icon(Icons.local_drink), label: 'Su'),
          BottomNavigationBarItem(
            icon: Icon(Icons.monitor_weight),
            label: 'Kilo',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book),
            label: 'KBuddy', 
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFFF27A23),
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

class DashboardContent extends StatefulWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateChange;

  const DashboardContent({
    super.key,
    required this.selectedDate,
    required this.onDateChange,
  });

  @override
  State<DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<DashboardContent> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  int _calorieGoal = 2200;
  double _carbsGoal = 250, _proteinGoal = 120, _fatGoal = 70;

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _calorieGoal = prefs.getInt('calorieGoal') ?? 2200;
        _carbsGoal = (_calorieGoal * 0.50) / 4;
        _proteinGoal = (_calorieGoal * 0.20) / 4;
        _fatGoal = (_calorieGoal * 0.30) / 9;
      });
    }
  }

  Future<void> _addFoodToMeal(String mealTitle) async {
    if (!mounted) return;
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _buildAddFoodMenu(),
    );

    if (result != null && _currentUser != null) {
      final now = DateTime.now();
      final dateToSave = DateTime(
        widget.selectedDate.year,
        widget.selectedDate.month,
        widget.selectedDate.day,
        now.hour,
        now.minute,
      );
      await _firestore
          .collection('users')
          .doc(_currentUser!.uid)
          .collection(mealTitle)
          .add({
            'name': result['food_name'],
            'calories': result['calories'],
            'carbs': result['carbs'],
            'protein': result['protein'],
            'fat': result['fat'],
            'timestamp': Timestamp.fromDate(dateToSave),
          });

      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${result['food_name']} eklendi!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Widget _buildAddFoodMenu() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Wrap(
        children: <Widget>[
          ListTile(
            leading: const Icon(Icons.camera_alt, color: Color(0xFFF27A23)),
            title: const Text('Fotoğrafla Ekle'),
            onTap: () async {
              final photoResult = await Navigator.push<Map<String, dynamic>>(
                context,
                MaterialPageRoute(builder: (context) => CalPredictor()),
              );
              if (mounted) Navigator.pop(context, photoResult);
            },
          ),
          ListTile(
            leading: const Icon(Icons.edit, color: Color(0xFFF27A23)),
            title: const Text('Manuel Ekle'),
            onTap: () async {
              final manualResult = await Navigator.push<Map<String, dynamic>>(
                context,
                MaterialPageRoute(
                  builder: (context) => const ManualEntryPage(),
                ),
              );
              if (mounted) Navigator.pop(context, manualResult);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _deleteFoodItem({
    required String mealTitle,
    required String foodId,
  }) async {
    if (_currentUser == null) return;
    await _firestore
        .collection('users')
        .doc(_currentUser!.uid)
        .collection(mealTitle)
        .doc(foodId)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null)
      return const Center(child: Text("Giriş yapılmamış."));

    final mealNames = ['Breakfast', 'Lunch', 'Dinner', 'Snacks'];
    final streams = mealNames.map((meal) {
      final startOfDay = Timestamp.fromDate(
        DateTime(
          widget.selectedDate.year,
          widget.selectedDate.month,
          widget.selectedDate.day,
        ),
      );
      final endOfDay = Timestamp.fromDate(
        DateTime(
          widget.selectedDate.year,
          widget.selectedDate.month,
          widget.selectedDate.day + 1,
        ),
      );
      return _firestore
          .collection('users')
          .doc(_currentUser!.uid)
          .collection(meal)
          .where('timestamp', isGreaterThanOrEqualTo: startOfDay)
          .where('timestamp', isLessThan: endOfDay)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => FoodItem.fromFirestore(doc))
                .toList(),
          );
    }).toList();

    return StreamBuilder<List<List<FoodItem>>>(
      stream: Rx.zip(streams, (List<List<FoodItem>> values) => values),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.hasError) {
          return const Center(child: Text("Veri yüklenemedi."));
        }

        final allMeals = snapshot.data!;
        final allFoodItems = allMeals.expand((list) => list).toList();
        final caloriesEaten = allFoodItems.fold(
          0,
          (sum, item) => sum + item.calories,
        );
        final carbsEaten = allFoodItems.fold(
          0.0,
          (sum, item) => sum + item.carbs,
        );
        final proteinEaten = allFoodItems.fold(
          0.0,
          (sum, item) => sum + item.protein,
        );
        final fatEaten = allFoodItems.fold(0.0, (sum, item) => sum + item.fat);

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildCalorieCircle(caloriesEaten),
                const SizedBox(height: 24),
                _buildMacrosSection(carbsEaten, proteinEaten, fatEaten),
                const SizedBox(height: 24),
                _buildDateSelector(),
                const SizedBox(height: 16),
                for (int i = 0; i < mealNames.length; i++)
                  _buildMealSection(mealNames[i], allMeals[i]),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCalorieCircle(int caloriesEaten) {
    double percent = _calorieGoal > 0 ? caloriesEaten / _calorieGoal : 0;
    if (percent > 1) percent = 1;
    return CircularPercentIndicator(
      radius: 100.0,
      lineWidth: 20.0,
      percent: percent,
      animation: true,
      center: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$caloriesEaten',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 32),
          ),
          const Text(
            'YENEN',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            '${_calorieGoal - caloriesEaten}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 48),
          ),
          const Text(
            'KALAN KCAL',
            style: TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ],
      ),
      circularStrokeCap: CircularStrokeCap.round,
      backgroundColor: Colors.grey.shade300,
      linearGradient: const LinearGradient(
        colors: [
          Colors.greenAccent,
          Colors.lightGreen,
          Colors.yellow,
          Colors.orange,
          Colors.red,
        ],
      ),
    );
  }

  Widget _buildMacrosSection(
    double carbsEaten,
    double proteinEaten,
    double fatEaten,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildMacroInfo('Carbs', carbsEaten, _carbsGoal, Colors.orange),
            _buildMacroInfo('Protein', proteinEaten, _proteinGoal, Colors.pink),
            _buildMacroInfo('Fat', fatEaten, _fatGoal, Colors.blue),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroInfo(String title, double eaten, double goal, Color color) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SizedBox(
          width: 80,
          child: LinearProgressIndicator(
            value: goal > 0 ? eaten / goal : 0,
            backgroundColor: color.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${eaten.toStringAsFixed(0)} / ${goal.toStringAsFixed(0)}g',
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildDateSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => widget.onDateChange(
            widget.selectedDate.subtract(const Duration(days: 1)),
          ),
        ),
        Text(
          DateFormat('d MMM, EEEE').format(widget.selectedDate),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: () => widget.onDateChange(
            widget.selectedDate.add(const Duration(days: 1)),
          ),
        ),
      ],
    );
  }

  Widget _buildMealSection(String title, List<FoodItem> foods) {
    int totalCalories = foods.fold(0, (sum, item) => sum + item.calories);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      '$totalCalories kcal',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, color: Color(0xFFF27A23)),
                      onPressed: () => _addFoodToMeal(title),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(),
            if (foods.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20.0),
                child: Text(
                  'Henüz bir şey eklemedin.',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              ...foods
                  .map(
                    (food) => Dismissible(
                      key: Key(food.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (direction) {
                        _deleteFoodItem(mealTitle: title, foodId: food.id);
                        if (mounted)
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${food.name} silindi.')),
                          );
                      },
                      child: ListTile(
                        title: Text(food.name),
                        trailing: Text('${food.calories} kcal'),
                      ),
                    ),
                  )
                  .toList(),
          ],
        ),
      ),
    );
  }
}
