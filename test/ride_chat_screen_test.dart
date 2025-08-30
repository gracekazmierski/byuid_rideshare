import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:byui_rideshare/screens/chat/ride_chat_screen.dart';
import 'package:byui_rideshare/models/chat_message.dart';
import 'mocks/mocks.mocks.dart'; // generated
import 'package:mockito/mockito.dart';

void main() {
  testWidgets('Chat screen renders messages', (WidgetTester tester) async {
    final mockChatService = MockChatService();
    final mockUserService = MockIUserService();
    final mockUser = MockUser();

    // Setup fake user
    when(mockUser.uid).thenReturn('user1');

    // Stub message stream
    when(mockChatService.getMessages(any)).thenAnswer(
      (_) => Stream.value([
        ChatMessage(
          senderId: 'user1',
          text: 'Hello',
          timestamp: Timestamp.now(),
        ),
      ]),
    );

    // Stub getUserName
    when(mockUserService.getUserName('user1')).thenAnswer(
      (_) async => 'John Doe',
    );

    // Build widget
    await tester.pumpWidget(MaterialApp(
      home: RideChatScreen(
        rideId: 'ride123',
        chatService: mockChatService,
        userService: mockUserService,
        currentUser: mockUser, rideTitle: '', // Inject mock user
      ),
    ));

    // Allow StreamBuilder and FutureBuilder to resolve
    await tester.pump(); // Triggers stream
    await tester.pumpAndSettle(); // Waits for FutureBuilder

    expect(find.text('Hello'), findsOneWidget);      // Message text
    expect(find.text('John Doe'), findsOneWidget);   // Sender name
  });
}
