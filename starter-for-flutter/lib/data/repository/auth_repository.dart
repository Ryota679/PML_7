import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' show User;

class AuthRepository {
  final Account _account;

  AuthRepository(Client client) : _account = Account(client);

  Future<void> login(String email, String password) async {
    await _account.createEmailPasswordSession(
      email: email,
      password: password,
    );
  }

  Future<User> getAccount() async {
    return await _account.get();
  }
}
