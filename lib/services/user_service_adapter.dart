import 'package:byui_rideshare/services/user_service_interface.dart';
import 'user_service.dart';

class UserServiceAdapter implements IUserService {
  @override
  Future<String?> getUserName(String uid) {
    // Assuming getUserName is static, call like this:
    return UserService.getUserName(uid);
  }
}
