import 'package:mockito/annotations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:byui_rideshare/services/chat_service.dart';
import 'package:byui_rideshare/services/user_service_interface.dart';

@GenerateMocks([ChatService, IUserService, User])
void main() {}
