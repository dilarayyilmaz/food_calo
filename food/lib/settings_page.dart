import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  String? _gender; 
  String? _activityLevel; 

  @override
  void initState() {
    super.initState();
    _loadUserData(); 
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _ageController.text = (prefs.getInt('age') ?? '').toString();
      _weightController.text = (prefs.getDouble('weight') ?? '').toString();
      _heightController.text = (prefs.getInt('height') ?? '').toString();
      _gender = prefs.getString('gender');
      _activityLevel = prefs.getString('activityLevel');
    });
  }

  Future<void> _saveUserData() async {
    if (_formKey.currentState!.validate()) {
      final prefs = await SharedPreferences.getInstance();

      int age = int.tryParse(_ageController.text) ?? 0;
      double weight = double.tryParse(_weightController.text) ?? 0.0;
      int height = int.tryParse(_heightController.text) ?? 0;

      await prefs.setInt('age', age);
      await prefs.setDouble('weight', weight);
      await prefs.setInt('height', height);
      if (_gender != null) await prefs.setString('gender', _gender!);
      if (_activityLevel != null)
        await prefs.setString('activityLevel', _activityLevel!);

      double bmr;
      if (_gender == 'Erkek') {
        bmr = (10 * weight) + (6.25 * height) - (5 * age) + 5;
      } else {
        bmr = (10 * weight) + (6.25 * height) - (5 * age) - 161;
      }

      Map<String, double> activityMultipliers = {
        'Hareketsiz': 1.2,
        'Az Aktif': 1.375,
        'Orta Aktif': 1.55,
        'Çok Aktif': 1.725,
        'Ekstra Aktif': 1.9,
      };

      double tdee = bmr * (activityMultipliers[_activityLevel] ?? 1.2);

      await prefs.setInt('calorieGoal', tdee.round());

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bilgiler kaydedildi! Hedefleriniz güncellendi.'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(
        context,
        true,
      ); 
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEF7F1),
      appBar: AppBar(title: const Text('Profilim & Ayarlar')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField(_ageController, 'Yaş'),
              const SizedBox(height: 16),
              _buildTextField(_weightController, 'Kilo (kg)'),
              const SizedBox(height: 16),
              _buildTextField(_heightController, 'Boy (cm)'),
              const SizedBox(height: 24),
              _buildDropdown(
                'Cinsiyet',
                ['Erkek', 'Kadın'],
                _gender,
                (val) => setState(() => _gender = val),
              ),
              const SizedBox(height: 16),
              _buildDropdown(
                'Aktivite Seviyesi',
                [
                  'Hareketsiz',
                  'Az Aktif',
                  'Orta Aktif',
                  'Çok Aktif',
                  'Ekstra Aktif',
                ],
                _activityLevel,
                (val) => setState(() => _activityLevel = val),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _saveUserData,
                child: const Text('Kaydet ve Hedefleri Güncelle'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  TextFormField _buildTextField(
    TextEditingController controller,
    String label,
  ) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Lütfen $label girin';
        }
        if (double.tryParse(value) == null) {
          return 'Geçerli bir sayı girin';
        }
        return null;
      },
    );
  }
  DropdownButtonFormField<String> _buildDropdown(
    String label,
    List<String> items,
    String? value,
    Function(String?) onChanged,
  ) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      value: value,
      items: items
          .map((item) => DropdownMenuItem<String>(
                value: item,
                child: Text(item),
              ))
          .toList(),
      onChanged: onChanged,
      validator: (val) => val == null || val.isEmpty ? 'Lütfen $label seçin' : null,
    );
  }
}
