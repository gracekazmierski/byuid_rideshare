import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_message.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> sendMessage({
    required String rideId,
    required ChatMessage message,
  }) async {
    await _firestore
        .collection('rides')
        .doc(rideId)
        .collection('messages')
        .add(message.toMap());
  }

  Stream<List<ChatMessage>> getMessages(String rideId) {
    return _firestore
        .collection('rides')
        .doc(rideId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatMessage.fromDoc(doc))
            .toList());
  }
}
