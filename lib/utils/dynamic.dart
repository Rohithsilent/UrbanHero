import 'package:shared_preferences/shared_preferences.dart';

Future<void> saveUserData(String username, String email) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('username', username);
  await prefs.setString('email', email);
}
