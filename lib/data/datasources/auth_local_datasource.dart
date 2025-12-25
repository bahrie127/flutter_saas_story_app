import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/auth_response_model.dart';

class AuthLocalDatasource {
  Future<void> saveAuth(AuthResponseModel auth) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth', jsonEncode(auth.toJson()));
  }

  Future<AuthResponseModel?> getAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final authString = prefs.getString('auth');
    if (authString != null) {
      return AuthResponseModel.fromJson(jsonDecode(authString));
    }
    return null;
  }

  Future<void> clearAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth');
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('auth');
  }
}
