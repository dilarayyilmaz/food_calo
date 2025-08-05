import 'package:flutter/material.dart';

class MealLogPage extends StatelessWidget {
  // Bu sayfa, gösterilecek yemek listesini dışarıdan bir parametre olarak alır.
  final List<Map<String, dynamic>> loggedMeals;

  const MealLogPage({super.key, required this.loggedMeals});

  @override
  Widget build(BuildContext context) {
    // Toplam kaloriyi hesaplayalım
    final int totalCalories = loggedMeals.fold(
      0,
      (sum, item) => sum + (item['calories'] as int),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Yemek Günlüğüm'),
        backgroundColor: const Color(0xFFF27A23),
        foregroundColor: Colors.white,
        actions: [
          // Toplam kaloriyi AppBar'da gösterelim
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Text(
                '$totalCalories kcal',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      backgroundColor: const Color(0xFFFDE8D8),
      body:
          // Eğer liste boşsa, kullanıcıya bir mesaj göster.
          loggedMeals.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.book_outlined, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Günlüğünüz henüz boş.',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            )
          // Eğer listede yemek varsa, ListView ile göster.
          : ListView.builder(
              itemCount: loggedMeals.length,
              itemBuilder: (context, index) {
                final meal = loggedMeals[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFF27A23),
                      child: Icon(Icons.fastfood, color: Colors.white),
                    ),
                    title: Text(
                      meal['food_name'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Carbs: ${meal['carbs'].toStringAsFixed(1)}g, Protein: ${meal['protein'].toStringAsFixed(1)}g, Fat: ${meal['fat'].toStringAsFixed(1)}g',
                    ),
                    trailing: Text(
                      '${meal['calories']} kcal',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFF27A23),
                        fontSize: 16,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
