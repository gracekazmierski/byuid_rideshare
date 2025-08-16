import 'package:byui_rideshare/services/user_service_interface.dart';
import 'user_service.dart';

class UserServiceAdapter implements IUserService {
  @override
  Future<String?> getUserName(String uid) {
    return UserService.getUserName(uid);
  }
}
