import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'recipe_detail_page.dart'; 

class Recipe {
  final String id;
  final String title;
  final String ingredients;
  final String instructions;

  Recipe({
    required this.id,
    required this.title,
    required this.ingredients,
    required this.instructions,
  });

  factory Recipe.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Recipe(
      id: doc.id,
      title: data['title'] ?? '',
      ingredients: data['ingredients'] ?? '',
      instructions: data['instructions'] ?? '',
    );
  }
}

class MammaBookPage extends StatefulWidget {
  const MammaBookPage({super.key});

  @override
  State<MammaBookPage> createState() => _MammaBookPageState();
}

class _MammaBookPageState extends State<MammaBookPage> {
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  Future<void> _showAddRecipeDialog() async {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final ingredientsController = TextEditingController();
    final instructionsController = TextEditingController();

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFFEF7F1),
          title: const Text('Yeni Tarif Ekle'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextFormField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Tarif Adı'),
                    validator: (value) =>
                        value!.isEmpty ? 'Bu alan boş bırakılamaz' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: ingredientsController,
                    decoration: const InputDecoration(
                      labelText: 'Malzemeler (Her birini yeni satıra yazın)',
                    ),
                    maxLines: 4,
                    validator: (value) =>
                        value!.isEmpty ? 'Bu alan boş bırakılamaz' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: instructionsController,
                    decoration: const InputDecoration(
                      labelText: 'Yapılışı (Adım adım anlatın)',
                    ),
                    maxLines: 6,
                    validator: (value) =>
                        value!.isEmpty ? 'Bu alan boş bırakılamaz' : null,
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('İptal'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Kaydet'),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  if (_currentUser != null) {
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(_currentUser!.uid)
                        .collection('my_recipes')
                        .add({
                          'title': titleController.text.trim(),
                          'ingredients': ingredientsController.text.trim(),
                          'instructions': instructionsController.text.trim(),
                          'createdAt': Timestamp.now(),
                        });
                    if (mounted) Navigator.of(context).pop();
                  }
                }
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
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 8.0, 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "",
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.add_circle_outline,
                    color: Color(0xFFF27A23),
                    size: 32,
                  ),
                  onPressed: _showAddRecipeDialog,
                  tooltip: 'Yeni Tarif Ekle',
                ),
              ],
            ),
          ),
          Expanded(
            child: _currentUser == null
                ? const Center(
                    child: Text(
                      'Tariflerinizi görmek için giriş yapmalısınız.',
                    ),
                  )
                : StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(_currentUser!.uid)
                        .collection('my_recipes')
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting)
                        return const Center(child: CircularProgressIndicator());
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24.0),
                            child: Text(
                              'Henüz hiç tarif kaydetmedin.\nSağ üstteki + butonuna tıkla!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        );
                      }
                      final recipesDocs = snapshot.data!.docs;
                      return ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: recipesDocs.length,
                        itemBuilder: (context, index) {
                          final recipe = Recipe.fromFirestore(
                            recipesDocs[index],
                          );
                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            child: ListTile(
                              title: Text(
                                recipe.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                recipe.ingredients,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        RecipeDetailPage(recipe: recipe),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
