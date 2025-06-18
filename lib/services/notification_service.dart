import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:byui_rideshare/models/notification_item.dart';

class NotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Stream<List<NotificationItem>> fetchNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => NotificationItem.fromMap(doc.data(), doc.id))
            .toList());
  }
}
