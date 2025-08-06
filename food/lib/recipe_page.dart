import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'mamma_book_page.dart';
import 'recipe_detail_page.dart';

class RecipePage extends StatelessWidget {
  const RecipePage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFFEF7F1),
        appBar: TabBar(
          tabs: const [
            Tab(icon: Icon(Icons.smart_toy_outlined), text: 'ChefBot'),
            Tab(icon: Icon(Icons.auto_stories_outlined), text: "Mamma's Book"),
          ],
          labelColor: const Color(0xFFF27A23),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFFF27A23),
          indicatorSize: TabBarIndicatorSize.tab,
        ),
        body: const TabBarView(children: [ChefBotTab(), MammaBookPage()]),
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  bool isRecipe;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.isRecipe = false,
  });
}

class ChefBotTab extends StatefulWidget {
  const ChefBotTab({super.key});
  @override
  State<ChefBotTab> createState() => _ChefBotTabState();
}

class _ChefBotTabState extends State<ChefBotTab> {
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  final String _serverIp =
      'http://192.168.1.80:5000/recipe_chat'; // KENDİ IP ADRESİNİ KONTROL ET

  @override
  void initState() {
    super.initState();
    _messages.add(
      ChatMessage(
        text:
            "Merhaba! Ben Mamma Mia'nın mutfak şefiyim. Nasıl bir tarif istersin?",
        isUser: false,
      ),
    );
  }

  Future<void> _sendMessage() async {
    final text = _controller.text;
    if (text.isEmpty) return;
    setState(() {
      _messages.insert(0, ChatMessage(text: text, isUser: true));
      _isLoading = true;
      _messages.insert(0, ChatMessage(text: "...", isUser: false));
    });
    _controller.clear();
    try {
      final response = await http.post(
        Uri.parse(_serverIp),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'question': text}),
      );
      setState(() {
        _messages.removeAt(0);
        if (response.statusCode == 200) {
          final responseBody = jsonDecode(utf8.decode(response.bodyBytes));
          String answer = responseBody['answer'];
          bool isRecipe =
              answer.contains("###BAŞLIK###") &&
              answer.contains("###MALZEMELER###") &&
              answer.contains("###YAPILIŞI###");
          _messages.insert(
            0,
            ChatMessage(text: answer, isUser: false, isRecipe: isRecipe),
          );
        } else {
          _messages.insert(
            0,
            ChatMessage(text: 'Üzgünüm, bir hata oluştu.', isUser: false),
          );
        }
      });
    } catch (e) {
      setState(() {
        _messages.removeAt(0);
        _messages.insert(
          0,
          ChatMessage(
            text: 'Sunucuya bağlanılamadı. Lütfen bağlantını kontrol et.',
            isUser: false,
          ),
        );
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveRecipeToBook(String recipeText) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tarifi kaydetmek için giriş yapmalısınız.'),
        ),
      );
      return;
    }

    try {
      final parts = recipeText
          .split(RegExp(r'###BAŞLIK###|###MALZEMELER###|###YAPILIŞI###'))
          .where((s) => s.trim().isNotEmpty)
          .toList();
      if (parts.length >= 3) {
        final title = parts[0].trim();
        final ingredients = parts[1].trim();
        final instructions = parts[2].trim();

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('my_recipes')
            .add({
              'title': title,
              'ingredients': ingredients,
              'instructions': instructions,
              'createdAt': Timestamp.now(),
            });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('"$title" tarifi Mamma\'s Book\'a eklendi!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tarif formatı anlaşılamadı, kaydedilemedi.'),
              backgroundColor: Colors.orange,
            ),
          );
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tarif kaydedilirken bir hata oluştu.'),
            backgroundColor: Colors.red,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            reverse: true,
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final message = _messages[index];
              return _buildMessageBubble(message);
            },
          ),
        ),
        _buildTextInput(),
      ],
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    if (!message.isUser && message.text == "...") {
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 5),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 5),
            ],
          ),
          child: const SizedBox(
            width: 40,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    Widget messageBubble = Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.75,
      ),
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: message.isUser ? const Color(0xFFF27A23) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 5),
        ],
      ),
      child: Text(
        message.text,
        style: TextStyle(color: message.isUser ? Colors.white : Colors.black87),
      ),
    );

    if (message.isRecipe) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8.0, right: 8.0),
              child: messageBubble,
            ),
            Positioned(
              top: -10,
              right: -10,
              child: Material(
                color: Colors.white,
                shape: const CircleBorder(),
                elevation: 4,
                child: IconButton(
                  icon: const Icon(Icons.add, color: Colors.green),
                  tooltip: 'Deftere Ekle',
                  onPressed: () => _saveRecipeToBook(message.text),
                  splashRadius: 20,
                  iconSize: 24,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: messageBubble,
    );
  }

  Widget _buildTextInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            color: Colors.grey.withOpacity(0.1),
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration.collapsed(
                hintText: 'Bir şeyler yaz...',
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.send,
              color: _isLoading ? Colors.grey : const Color(0xFFF27A23),
            ),
            onPressed: _isLoading ? null : _sendMessage,
          ),
        ],
      ),
    );
  }
}
