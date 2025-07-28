import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:byui_rideshare/services/chat_service.dart';
import 'package:byui_rideshare/models/chat_message.dart';

class RideChatScreen extends StatefulWidget {
  final String rideId;

  const RideChatScreen({Key? key, required this.rideId}) : super(key: key);

  @override
  State<RideChatScreen> createState() => _RideChatScreenState();
}

class _RideChatScreenState extends State<RideChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _controller = TextEditingController();
  final user = FirebaseAuth.instance.currentUser;

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty || user == null) return;

    final message = ChatMessage(
      senderId: user!.uid,
      text: text,
      timestamp: Timestamp.now(),
    );

    _chatService.sendMessage(rideId: widget.rideId, message: message);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Ride Chat')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: _chatService.getMessages(widget.rideId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
                final messages = snapshot.data!;
                return ListView(
                  padding: EdgeInsets.all(8),
                  children: messages.map((msg) {
                    final isMe = msg.senderId == user?.uid;
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: EdgeInsets.symmetric(vertical: 2),
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blue[100] : Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(msg.text),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
          Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(child: TextField(controller: _controller)),
                IconButton(icon: Icon(Icons.send), onPressed: _sendMessage),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
