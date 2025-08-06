import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChatMessage {
  final String text;
  final bool isUser;
  ChatMessage({required this.text, required this.isUser});
}

class RecipePage extends StatefulWidget {
  const RecipePage({super.key});

  @override
  State<RecipePage> createState() => _RecipePageState();
}

class _RecipePageState extends State<RecipePage> {
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  // Kendi IP adresini buraya yazmalısın
  final String _serverIp = 'http://192.168.1.80:5000/recipe_chat';

  @override
  void initState() {
    super.initState();
    _messages.add(
      ChatMessage(
        text:
            "Merhaba! Ben Mamma Mia'nın mutfak şefiyim. Nasıl bir tarif istersin? (Örn: 'Hızlı bir kahvaltı tarifi')",
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
      _messages.insert(
        0,
        ChatMessage(text: "...", isUser: false),
      ); 
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
          _messages.insert(
            0,
            ChatMessage(text: responseBody['answer'], isUser: false),
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
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFEF7F1), 
      child: Column(
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
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
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
          style: TextStyle(
            color: message.isUser ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildTextInput() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(blurRadius: 10, color: Colors.grey.withOpacity(0.2)),
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
