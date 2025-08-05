import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

import 'chat_page.dart';

import 'package:google_fonts/google_fonts.dart';

class CalPredictor extends StatefulWidget {
  @override
  _CalPredictorState createState() => _CalPredictorState();
}

class _CalPredictorState extends State<CalPredictor> {
  File? _image;
  String _resultText = '';
  bool _loading = false;
  final picker = ImagePicker();

  Map<String, dynamic>? _foodData;
  int _servings = 1;

  final List<Map<String, dynamic>> _loggedMeals = [];

  final String _serverIp = 'http://192.168.1.5:5000/predict';

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _foodData = null;
        _resultText = '';
        _servings = 1;
        _loading = true;
      });
      await _uploadAndPredict(_image!);
    }
  }

  Future<void> _uploadAndPredict(File imageFile) async {
    var request = http.MultipartRequest('POST', Uri.parse(_serverIp));
    request.files.add(
      await http.MultipartFile.fromPath('image', imageFile.path),
    );
    try {
      var response = await request.send();
      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        var json = jsonDecode(responseData);
        setState(() {
          _foodData = json;
        });
      } else {
        var responseData = await response.stream.bytesToString();
        var json = jsonDecode(responseData);
        setState(() {
          _resultText =
              'Prediction failed: ${json['error'] ?? 'Unknown error'}';
        });
      }
    } catch (e) {
      setState(() {
        _resultText = 'Error connecting to the server: $e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  void _logMeal() {
    if (_foodData == null) return;

    final Map<String, dynamic> mealToLog = {
      'food_name': _foodData!['food_name'],
      'calories': (_foodData!['calories'] as num).toInt() * _servings,
      'protein': (_foodData!['protein'] as num) * _servings,
      'fat': (_foodData!['fat'] as num) * _servings,
      'carbs': (_foodData!['carbs'] as num) * _servings,
    };

    setState(() {
      _loggedMeals.add(mealToLog);
      _image = null;
      _foodData = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${mealToLog['food_name']} başarıyla günlüğe eklendi!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDE8D8),

      appBar: AppBar(
        title: Text(
          'Mamma Mia',
          style: GoogleFonts.pacifico(fontSize: 28, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFF27A23),
        elevation: 0,
        automaticallyImplyLeading: false, 
      ),

     
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatPage(mealHistory: _loggedMeals),
            ),
          );
        },
        icon: const Icon(Icons.chat_bubble_outline),
        label: const Text('Danışman'),
        backgroundColor: const Color(0xFFF27A23),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [const SizedBox(height: 20), _buildContent()],
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildContent() {
    if (_image == null) {
      return _buildImagePickerButton();
    } else {
      return _buildFoodCard();
    }
  }

  Widget _buildImagePickerButton() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 100),
          // İkonu resimdeki gibi değiştirdim
          const Icon(Icons.restaurant, size: 80, color: Colors.black54),
          const SizedBox(height: 20),
          const Text(
            'Get nutritional information from a photo.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, color: Colors.black54),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: _pickImage,
            icon: const Icon(Icons.camera_alt),
            label: const Text('Select a Food Image'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF27A23),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

 
  Widget _buildFoodCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            _buildFoodImage(),
            if (!_loading && _foodData != null)
              _buildDetailsSection()
            else if (_loading)
              const Padding(
                padding: EdgeInsets.all(50.0),
                child: CircularProgressIndicator(),
              )
            else
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  _resultText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                ),
              ),
            if (!_loading && _foodData != null) _buildLogMealButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildLogMealButton() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _logMeal, // Artık yeni loglama fonksiyonunu çağırıyor
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: const Text(
            'Log Meal',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFoodImage() {
    String foodName = "Analyzing...";
    if (!_loading && _foodData != null) {
      foodName = _foodData!['food_name'] ?? 'Unknown Food';
    }
    return Stack(
      children: [
        Image.file(
          _image!,
          width: double.infinity,
          height: 200,
          fit: BoxFit.cover,
        ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                stops: const [0.0, 0.6],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 16,
          left: 16,
          child: Text(
            foodName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsSection() {
    final calories = (_foodData!['calories'] as num?)?.toInt() ?? 0;
    final carbs = (_foodData!['carbs'] as num?)?.round() ?? 0;
    final protein = (_foodData!['protein'] as num?)?.round() ?? 0;
    final fat = (_foodData!['fat'] as num?)?.round() ?? 0;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCaloriesRow(calories * _servings),
          const SizedBox(height: 20),
          _buildServingsRow(),
          const SizedBox(height: 20),
          _buildMacronutrientsHeader(),
          const SizedBox(height: 12),
          _buildMacronutrientsRow(
            carbs * _servings,
            protein * _servings,
            fat * _servings,
          ),
        ],
      ),
    );
  }

  Widget _buildCaloriesRow(int totalCalories) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Total calories',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 5,
              ),
            ],
          ),
          child: Row(
            children: [
              Text(
                '$totalCalories kcal',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.edit, size: 18, color: Colors.black54),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildServingsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Servings',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: () {
                  if (_servings > 1) setState(() => _servings--);
                },
                constraints: const BoxConstraints(),
              ),
              Text(
                _servings.toString(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => setState(() => _servings++),
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMacronutrientsHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Macronutrients',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        TextButton.icon(
          onPressed: () {},
          icon: const Text('Edit', style: TextStyle(color: Colors.grey)),
          label: const Icon(Icons.edit, size: 16, color: Colors.grey),
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: const Size(50, 30),
          ),
        ),
      ],
    );
  }

  Widget _buildMacronutrientsRow(
    int totalCarbs,
    int totalProtein,
    int totalFat,
  ) {
    return Row(
      children: [
        _buildNutrientCard(
          title: 'Carbs',
          value: '${totalCarbs}g',
          color: const Color(0xFFFBC02D),
          progress: 0.7,
        ),
        const SizedBox(width: 12),
        _buildNutrientCard(
          title: 'Protein',
          value: '${totalProtein}g',
          color: const Color(0xFFE57373),
          progress: 0.5,
        ),
        const SizedBox(width: 12),
        _buildNutrientCard(
          title: 'Fat',
          value: '${totalFat}g',
          color: const Color(0xFF64B5F6),
          progress: 0.5,
        ),
      ],
    );
  }

  Widget _buildNutrientCard({
    required String title,
    required String value,
    required Color color,
    required double progress,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 10,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(backgroundColor: color, radius: 4),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Center(
              child: SizedBox(
                height: 60,
                width: 60,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: 1,
                      backgroundColor: color.withOpacity(0.2),
                      strokeWidth: 8,
                    ),
                    CircularProgressIndicator(
                      value: progress,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      strokeWidth: 8,
                    ),
                    Center(
                      child: Text(
                        value,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
