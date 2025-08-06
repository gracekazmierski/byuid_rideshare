// ride_chat_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:byui_rideshare/services/chat_service.dart';
import 'package:byui_rideshare/services/user_service_interface.dart';
import 'package:byui_rideshare/services/user_service_adapter.dart';
import 'package:byui_rideshare/models/chat_message.dart';

class RideChatScreen extends StatefulWidget {
  final String rideId;
  final ChatService chatService;
  final IUserService userService;

  RideChatScreen({
    Key? key,
    required this.rideId,
    ChatService? chatService,
    IUserService? userService,
  })  : chatService = chatService ?? ChatService(),
        userService = userService ?? UserServiceAdapter(),
        super(key: key);

  @override
  State<RideChatScreen> createState() => _RideChatScreenState();
}

class _RideChatScreenState extends State<RideChatScreen> {
  final TextEditingController _controller = TextEditingController();

  // Cache of user names
  final Map<String, String> _nameCache = {};

  User? get user => FirebaseAuth.instance.currentUser;
  ChatService get _chatService => widget.chatService;

  // Get user name from cache or Firestore
  Future<String> _getUserName(String uid) async {
    if (_nameCache.containsKey(uid)) {
      return _nameCache[uid]!;
    }
    final name = await widget.userService.getUserName(uid) ?? "Unknown";
    _nameCache[uid] = name;
    return name;
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty || user == null) return;

    final message = ChatMessage(
      senderId: user!.uid,
      text: text,
      timestamp: Timestamp.now(),
    );

    widget.chatService.sendMessage(rideId: widget.rideId, message: message);
    _controller.clear();
  }

  // helper methods for formatting timestamps
  // This formats the timestamp to a more readable format
  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    return "${_monthName(date.month)} ${date.day}, ${date.year} "
          "${_formatHour(date.hour)}:${date.minute.toString().padLeft(2, '0')} "
          "${date.hour >= 12 ? 'PM' : 'AM'}";
  }

  String _formatHour(int hour) {
    final h = hour % 12;
    return h == 0 ? '12' : h.toString();
  }

  String _monthName(int month) {
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month];
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
                    return FutureBuilder<String>(
                      future: _getUserName(msg.senderId),
                      builder: (context, nameSnapshot) {
                        final name = nameSnapshot.data ?? 'Loading...';
                        return Align(
                          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: Column(
                            crossAxisAlignment:
                                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[700],
                                ),
                              ),
                              Container(
                                margin: EdgeInsets.only(top: 2),
                                padding: EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isMe ? Colors.blue[100] : Colors.grey[300],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(msg.text),
                                    SizedBox(height: 6),
                                    Text(
                                      _formatTimestamp(msg.timestamp),
                                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 6),
                            ],
                          ),
                        );
                      },
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
