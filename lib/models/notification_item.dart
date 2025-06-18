import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationItem {
  final String id;
  final String userId;
  final String title;
  final String body;
  final Timestamp timestamp;

  NotificationItem({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.timestamp,
  });

  factory NotificationItem.fromMap(Map<String, dynamic> data, String id) {
    return NotificationItem(
      id: id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      timestamp: data['timestamp'] ?? Timestamp.now(),
    );
  }
}
