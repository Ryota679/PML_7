import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' show User;

class AuthRepository {
  final Account _account;

  AuthRepository(Client client) : _account = Account(client);

  Future<void> login(String email, String password) async {
    try {
      await logout();
    } catch (e) {
      // Ignore errors from logout, as it's possible no session exists.
    }
    await _account.createEmailPasswordSession(
      email: email,
      password: password,
    );
  }

  Future<void> logout() async {
    await _account.deleteSession(sessionId: 'current');
  }

  Future<User> getAccount() async {
    return await _account.get();
  }
}
