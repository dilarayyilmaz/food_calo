import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'mamma_book_page.dart'; 

class RecipeDetailPage extends StatelessWidget {
  final Recipe recipe; 

  const RecipeDetailPage({super.key, required this.recipe});

  Future<void> _deleteRecipe(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tarifi Sil'),
        content: const Text(
          'Bu tarifi kalıcı olarak silmek istediğinizden emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('my_recipes')
          .doc(recipe.id)
          .delete();

      Navigator.pop(context); 
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEF7F1),
      appBar: AppBar(
        title: Text(
          recipe.title,
          style: GoogleFonts.pacifico(color: Colors.white),
        ),
        backgroundColor: const Color(0xFFF27A23),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _deleteRecipe(context),
            tooltip: 'Tarifi Sil',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Malzemeler'),
            const SizedBox(height: 8),
            _buildContentCard(recipe.ingredients),
            const SizedBox(height: 24),
            _buildSectionTitle('Yapılışı'),
            const SizedBox(height: 8),
            _buildContentCard(recipe.instructions, isNumbered: true),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildContentCard(String content, {bool isNumbered = false}) {
    final lines = content
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(lines.length, (index) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Text(
              isNumbered ? '${index + 1}. ${lines[index]}' : lines[index],
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
          );
        }),
      ),
    );
  }
}
