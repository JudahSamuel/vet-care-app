import 'package:flutter/material.dart';
import '../services/api_service.dart';

// Simple class to represent a chat message
class ChatMessage {
  final String text;
  final bool isUser; // True if the message is from the user, false if from AI

  ChatMessage({required this.text, required this.isUser});
}

class ChatScreen extends StatefulWidget {
  final String? petId;
  const ChatScreen({Key? key, this.petId}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _textController = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false; // To show a loading indicator
  final ScrollController _scrollController = ScrollController(); // To auto-scroll

  @override
  void initState() {
    super.initState();
    // Add an initial greeting from the AI
    _messages.add(ChatMessage(
      text: "Hello! Ask me anything about pet care. Remember to always consult a vet for serious issues.",
      isUser: false
    ));
  }

  void _scrollToBottom() {
    // A small delay ensures the list has built before we scroll
    Future.delayed(Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // Function to handle sending a message
  void _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    _textController.clear(); // Clear the input field

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true)); // Add user message
      _isLoading = true; // Show loading indicator
    });
    _scrollToBottom();

    // Send message to the backend/AI
    final result = await _apiService.askChatbot(text, petId: widget.petId);

    setState(() {
      _isLoading = false; // Hide loading indicator
      if (result['statusCode'] == 200) {
        _messages.add(ChatMessage(text: result['body']['reply'], isUser: false)); // Add AI reply
      } else {
        // Add an error message if something went wrong
        _messages.add(ChatMessage(text: result['body']['reply'] ?? "Sorry, something went wrong.", isUser: false));
      }
    });
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("PawTech AI Assistant"),
      ),
      body: Column(
        children: [
          // --- Message List ---
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessageBubble(message);
              },
            ),
          ),
          // --- Loading Indicator ---
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: LinearProgressIndicator(),
            ),
          // --- Input Area ---
          _buildInputArea(),
        ],
      ),
    );
  }

  // Builds the chat bubble for a single message
  Widget _buildMessageBubble(ChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5.0),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        decoration: BoxDecoration(
          color: message.isUser
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(15.0),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: message.isUser
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).colorScheme.onSecondaryContainer,
          ),
        ),
      ),
    );
  }

  // Builds the text input field and send button
  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            offset: Offset(0, -2),
            blurRadius: 4,
            color: Colors.black.withOpacity(0.1),
          )
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: "Ask about pet care...",
                border: InputBorder.none,
              ),
              onSubmitted: _isLoading ? null : _sendMessage, // Send on enter key
            ),
          ),
          IconButton(
            icon: Icon(Icons.send),
            onPressed: _isLoading ? null : () => _sendMessage(_textController.text),
            color: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }
}