import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:byui_rideshare/screens/chat/ride_chat_screen.dart';
import 'package:byui_rideshare/models/chat_message.dart';
import 'mocks.mocks.dart'; // generated
import 'package:mockito/mockito.dart';

void main() {
    testWidgets('Chat screen renders messages', (WidgetTester tester) async {
    final mockChatService = MockChatService();
    final mockUserService = MockIUserService();

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

    await tester.pumpWidget(MaterialApp(
      home: RideChatScreen(
        rideId: 'ride123',
        chatService: mockChatService,
        userService: mockUserService,
      ),
    ));

    await tester.pump(); // resolve stream and FutureBuilder

    expect(find.text('Hello'), findsOneWidget);
    expect(find.text('John Doe'), findsOneWidget);
  });
}
