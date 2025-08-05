import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ManualEntryPage extends StatefulWidget {
  const ManualEntryPage({super.key});

  @override
  State<ManualEntryPage> createState() => _ManualEntryPageState();
}

class _ManualEntryPageState extends State<ManualEntryPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _carbsController = TextEditingController();
  final _proteinController = TextEditingController();
  final _fatController = TextEditingController();

  bool _isLoading = false;
  // Kendi IP adresini buraya yazmalısın
  final String _serverIp = 'http://192.168.1.5:5000/get_macros';

  @override
  void dispose() {
    _nameController.dispose();
    _caloriesController.dispose();
    _carbsController.dispose();
    _proteinController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  Future<void> _fetchMacros() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen bir yemek adı girin.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse(_serverIp),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'food_name': _nameController.text}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data['error'] != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Hata: ${data['error']}'),
              backgroundColor: Colors.red,
            ),
          );
        } else {
          _caloriesController.text =
              (data['calories'] as num?)?.toString() ?? '0';
          _carbsController.text = (data['carbs'] as num?)?.toString() ?? '0.0';
          _proteinController.text =
              (data['protein'] as num?)?.toString() ?? '0.0';
          _fatController.text = (data['fat'] as num?)?.toString() ?? '0.0';
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Makro bilgileri otomatik dolduruldu!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Makro bilgileri bulunamadı.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sunucuya bağlanılamadı.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _saveAndGoBack() {
    if (_formKey.currentState!.validate()) {
      final Map<String, dynamic> manualData = {
        'food_name': _nameController.text,
        'calories': int.tryParse(_caloriesController.text) ?? 0,
        'carbs': double.tryParse(_carbsController.text) ?? 0.0,
        'protein': double.tryParse(_proteinController.text) ?? 0.0,
        'fat': double.tryParse(_fatController.text) ?? 0.0,
      };
      Navigator.of(context).pop(manualData);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEF7F1),
      appBar: AppBar(
        title: Text(
          'Manuel Ekle',
          style: GoogleFonts.pacifico(fontSize: 28, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFF27A23),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Yemek Adı',
                  hintText: 'Örn: Izgara Tavuk Göğsü',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  suffixIcon: _isLoading
                      ? const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : IconButton(
                          icon: const Icon(
                            Icons.search,
                            color: Color(0xFFF27A23),
                          ),
                          onPressed: _fetchMacros,
                          tooltip: 'Makroları Otomatik Bul',
                        ),
                ),
                validator: (value) => (value == null || value.isEmpty)
                    ? 'Lütfen bu alanı doldurun.'
                    : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                _caloriesController,
                'Kalori (kcal)',
                isNumber: true,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      _carbsController,
                      'Karbonhidrat (g)',
                      isNumber: true,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      _proteinController,
                      'Protein (g)',
                      isNumber: true,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      _fatController,
                      'Yağ (g)',
                      isNumber: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveAndGoBack,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF27A23),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: const Text('Öğüne Ekle'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  TextFormField _buildTextField(
    TextEditingController controller,
    String label, {
    bool isNumber = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Lütfen bu alanı doldurun.';
        }
        return null;
      },
    );
  }
}
