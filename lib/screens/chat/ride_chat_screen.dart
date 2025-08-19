import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:byui_rideshare/services/chat_service.dart';
import 'package:byui_rideshare/services/user_service_interface.dart';
import 'package:byui_rideshare/services/user_service_adapter.dart';
import 'package:byui_rideshare/models/chat_message.dart';
import 'package:byui_rideshare/theme/app_colors.dart';
import 'package:byui_rideshare/screens/profile/profile_view_screen.dart';

class RideChatScreen extends StatefulWidget {
  final String rideId;
  final String rideTitle;
  final ChatService chatService;
  final IUserService userService;
  final User? currentUser;

  RideChatScreen({
    Key? key,
    required this.rideId,
    required this.rideTitle,
    ChatService? chatService,
    IUserService? userService,
    this.currentUser,
  })  : chatService = chatService ?? ChatService(),
        userService = userService ?? UserServiceAdapter(),
        super(key: key);

  @override
  State<RideChatScreen> createState() => _RideChatScreenState();
}

class _RideChatScreenState extends State<RideChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final Map<String, String> _nameCache = {};
  User? get user => widget.currentUser ?? FirebaseAuth.instance.currentUser;
  ChatService get _chatService => widget.chatService;

  Future<String> _getUserName(String uid) async {
    if (_nameCache.containsKey(uid)) return _nameCache[uid]!;
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

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight + 40),
      child: Container(
        color: AppColors.byuiBlue,
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.rideTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22.0,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2.0),
                    const Text(
                      "Ride Chat",
                      style: TextStyle(
                        color: AppColors.blue100,
                        fontSize: 14.0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      backgroundColor: AppColors.gray50,
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: _chatService.getMessages(widget.rideId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data!;
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[messages.length - 1 - index];
                    final isMe = msg.senderId == user?.uid;

                    return FutureBuilder<String>(
                      future: _getUserName(msg.senderId),
                      builder: (context, nameSnap) {
                        final name = nameSnap.data ?? "Loading...";
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: isMe
                              ? MainAxisAlignment.end
                              : MainAxisAlignment.start,
                          children: [
                            if (!isMe)
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          ProfileViewScreen(userId: msg.senderId),
                                    ),
                                  );
                                },
                                child: CircleAvatar(
                                  radius: 16,
                                  backgroundColor: AppColors.byuiBlue.withOpacity(0.2),
                                  child: Text(
                                    name.isNotEmpty ? name[0].toUpperCase() : "?",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.byuiBlue,
                                    ),
                                  ),
                                ),
                              ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Column(
                                crossAxisAlignment: isMe
                                    ? CrossAxisAlignment.end
                                    : CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 10),
                                    margin: const EdgeInsets.symmetric(vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isMe
                                          ? AppColors.byuiBlue
                                          : Colors.grey.shade300,
                                      borderRadius: BorderRadius.only(
                                        topLeft: const Radius.circular(18),
                                        topRight: const Radius.circular(18),
                                        bottomLeft: Radius.circular(isMe ? 18 : 0),
                                        bottomRight: Radius.circular(isMe ? 0 : 18),
                                      ),
                                    ),
                                    child: Text(
                                      msg.text,
                                      style: TextStyle(
                                        color: isMe ? Colors.white : Colors.black87,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              ProfileViewScreen(userId: msg.senderId),
                                        ),
                                      );
                                    },
                                    child: Text(
                                      name,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textGray500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (isMe)
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: AppColors.byuiBlue.withOpacity(0.2),
                                child: const Text(
                                  "Me",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                    color: AppColors.byuiBlue,
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          const Divider(height: 1),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: "Type a message…",
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: AppColors.byuiBlue,
                    radius: 22,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
