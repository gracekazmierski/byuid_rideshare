// Interface for UserService to allow mocking in tests
abstract class IUserService {
  Future<String?> getUserName(String uid);
}
