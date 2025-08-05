import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async'; // Zaman aşımı için import
import 'dart:convert';

class ChatMessage {
  final String text;
  final bool isUser;
  ChatMessage({required this.text, required this.isUser});
}

class ChatPage extends StatefulWidget {
  final List<Map<String, dynamic>> mealHistory;
  const ChatPage({Key? key, required this.mealHistory}) : super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  final String _serverIp = 'http://192.168.1.5:5000/chat';

  @override
  void initState() {
    super.initState();
    _messages.add(
      ChatMessage(
        text:
            "Merhaba! Ben senin kişisel beslenme danışmanınım. Yemeklerinle ilgili veya genel olarak aklına takılanları sorabilirsin.",
        isUser: false,
      ),
    );
  }

  void _sendMessage() async {
    final text = _controller.text;
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.insert(0, ChatMessage(text: text, isUser: true));
      _isLoading = true;
    });
    _controller.clear();

    try {
      final response = await http
          .post(
            Uri.parse(_serverIp),
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
            body: jsonEncode({'question': text, 'history': widget.mealHistory}),
          )
          .timeout(const Duration(seconds: 30)); // 30 saniye sonra zaman aşımı

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          _messages.insert(0, ChatMessage(text: data['answer'], isUser: false));
        });
      } else {
        final errorData = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          _messages.insert(
            0,
            ChatMessage(
              text: "Bir hata oluştu:\n${errorData['error']}",
              isUser: false,
            ),
          );
        });
      }
    } on TimeoutException catch (_) {
      setState(() {
        _messages.insert(
          0,
          ChatMessage(
            text:
                "Sunucudan cevap alınamadı (zaman aşımı). Lütfen internet bağlantınızı kontrol edin veya daha sonra tekrar deneyin.",
            isUser: false,
          ),
        );
      });
    } on SocketException catch (_) {
      setState(() {
        _messages.insert(
          0,
          ChatMessage(
            text:
                "Sunucuya bağlanılamadı. Lütfen internet bağlantınızı ve sunucunun çalıştığını kontrol edin.",
            isUser: false,
          ),
        );
      });
    } catch (e) {
      setState(() {
        _messages.insert(
          0,
          ChatMessage(text: "Beklenmedik bir hata oluştu: $e", isUser: false),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text("Beslenme Danışmanı"),
        backgroundColor: const Color(0xFFFDE8D8),
        elevation: 1,
      ),
      backgroundColor: const Color(0xFFFDE8D8),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              padding: const EdgeInsets.all(8.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) =>
                  _buildMessageBubble(_messages[index]),
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: LinearProgressIndicator(),
            ),
          _buildMessageComposer(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: message.isUser ? const Color(0xFFF27A23) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
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

  Widget _buildMessageComposer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration.collapsed(
                hintText: 'Bir soru sorun...',
              ),
              onSubmitted: (value) => _sendMessage(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            color: const Color(0xFFF27A23),
            onPressed: _isLoading ? null : _sendMessage,
          ),
        ],
      ),
    );
  }
}
