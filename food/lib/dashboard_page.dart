import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart'; 

import 'cal_predictor.dart';
import 'water_tracker_page.dart';
import 'weight_tracker_page.dart';
import 'recipe_page.dart';
import 'settings_page.dart'; 
import 'manual_entry_page.dart'; 

class FoodItem {
  final String name;
  final int calories;
  final double carbs;
  final double protein;
  final double fat;

  FoodItem({
    required this.name,
    required this.calories,
    required this.carbs,
    required this.protein,
    required this.fat,
  });
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;
  int _calorieGoal = 2200;
  double _carbsGoal = 250, _proteinGoal = 120, _fatGoal = 70;
  DateTime _selectedDate = DateTime.now();
  final Map<String, List<FoodItem>> _meals = {
    'Breakfast': [],
    'Lunch': [],
    'Dinner': [],
    'Snacks': [],
  };

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _calorieGoal = prefs.getInt('calorieGoal') ?? _calorieGoal;
      _carbsGoal = (_calorieGoal * 0.50) / 4;
      _proteinGoal = (_calorieGoal * 0.20) / 4;
      _fatGoal = (_calorieGoal * 0.30) / 9;
    });
  }

  Future<void> _navigateToSettings() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const SettingsPage()),
    );
    if (result == true) {
      _loadGoals();
    }
  }

  void _onItemTapped(int index) {
    if (index == 1) {
      _addFoodToMeal('Snacks');
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  Future<void> _addFoodToMeal(String mealTitle) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFFF27A23)),
                title: const Text('Fotoğrafla Ekle'),
                onTap: () async {
                  final photoResult =
                      await Navigator.push<Map<String, dynamic>>(
                        context,
                        MaterialPageRoute(builder: (context) => CalPredictor()),
                      );
                  Navigator.pop(context, photoResult);
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit, color: Color(0xFFF27A23)),
                title: const Text('Manuel Ekle'),
                onTap: () async {
                  final manualResult =
                      await Navigator.push<Map<String, dynamic>>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ManualEntryPage(),
                        ),
                      );
                  Navigator.pop(context, manualResult);
                },
              ),
            ],
          ),
        );
      },
    );

    if (result != null) {
      final newFood = FoodItem(
        name: result['food_name'] ?? 'Unknown',
        calories: (result['calories'] as num?)?.toInt() ?? 0,
        carbs: (result['carbs'] as num?)?.toDouble() ?? 0.0,
        protein: (result['protein'] as num?)?.toDouble() ?? 0.0,
        fat: (result['fat'] as num?)?.toDouble() ?? 0.0,
      );

      setState(() => _meals[mealTitle]?.add(newFood));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${newFood.name} öğününe eklendi!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      DashboardContent(
        calorieGoal: _calorieGoal,
        meals: _meals,
        carbsGoal: _carbsGoal,
        proteinGoal: _proteinGoal,
        fatGoal: _fatGoal,
        selectedDate: _selectedDate,
        onDateChange: (newDate) => setState(() => _selectedDate = newDate),
        onAddFood: _addFoodToMeal,
      ),
      const SizedBox.shrink(),
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
        ],
      ),
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Ana Sayfa'),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt),
            label: 'Kalori',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.local_drink), label: 'Su'),
          BottomNavigationBarItem(
            icon: Icon(Icons.monitor_weight),
            label: 'Kilo',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book),
            label: 'Tarifler',
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

class DashboardContent extends StatelessWidget {
  final int calorieGoal;
  final Map<String, List<FoodItem>> meals;
  final double carbsGoal, proteinGoal, fatGoal;
  final DateTime selectedDate;
  final Function(DateTime) onDateChange;
  final Function(String) onAddFood;

  const DashboardContent({
    super.key,
    required this.calorieGoal,
    required this.meals,
    required this.carbsGoal,
    required this.proteinGoal,
    required this.fatGoal,
    required this.selectedDate,
    required this.onDateChange,
    required this.onAddFood,
  });

  int get caloriesEaten => meals.values
      .expand((list) => list)
      .fold(0, (sum, item) => sum + item.calories);
  double get carbsEaten => meals.values
      .expand((list) => list)
      .fold(0.0, (sum, item) => sum + item.carbs);
  double get proteinEaten => meals.values
      .expand((list) => list)
      .fold(0.0, (sum, item) => sum + item.protein);
  double get fatEaten => meals.values
      .expand((list) => list)
      .fold(0.0, (sum, item) => sum + item.fat);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildCalorieCircle(),
            const SizedBox(height: 24),
            _buildMacrosSection(),
            const SizedBox(height: 24),
            _buildDateSelector(),
            const SizedBox(height: 16),
            ...meals.entries
                .map((entry) => _buildMealSection(entry.key, entry.value))
                .toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildCalorieCircle() {
    double percent = calorieGoal > 0 ? caloriesEaten / calorieGoal : 0;
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
            '${calorieGoal - caloriesEaten}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 48),
          ),
          const Text(
            'KALAN KCAL',
            style: TextStyle(fontSize: 12, color: Colors.grey),
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

  Widget _buildMacrosSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildMacroInfo('Carbs', carbsEaten, carbsGoal, Colors.orange),
            _buildMacroInfo('Protein', proteinEaten, proteinGoal, Colors.pink),
            _buildMacroInfo('Fat', fatEaten, fatGoal, Colors.blue),
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
          onPressed: () =>
              onDateChange(selectedDate.subtract(const Duration(days: 1))),
        ),
        Text(
          DateFormat('d MMM, EEEE').format(selectedDate),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: () =>
              onDateChange(selectedDate.add(const Duration(days: 1))),
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
                      onPressed: () => onAddFood(title),
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
                    (food) => ListTile(
                      title: Text(food.name),
                      trailing: Text('${food.calories} kcal'),
                    ),
                  )
                  .toList(),
          ],
        ),
      ),
    );
  }
}
