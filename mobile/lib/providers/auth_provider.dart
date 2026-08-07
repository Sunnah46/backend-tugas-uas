import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';
import '../services/api_exception.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _api = ApiService.instance;
  final SharedPreferences _prefs;

  User? _user;
  String? _token;
  bool _initialized = false;
  bool _loading = false;

  AuthProvider(this._prefs);

  User? get user => _user;
  String? get token => _token;
  bool get initialized => _initialized;
  bool get loading => _loading;
  bool get isLoggedIn => _token != null;
  bool get isAdmin => _user?.isAdmin ?? false;

  static const _tokenKey = 'auth_token';
  static const _userKey = 'auth_user';

  Future<void> restoreSession() async {
    await null;
    final token = _prefs.getString(_tokenKey);
    final userJson = _prefs.getString(_userKey);

    if (token != null && userJson != null) {
      _token = token;
      _api.token = token;
      _user = User.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
      try {
        _user = await _api.me();
        await _saveUser(_user!);
      } on ApiException catch (e) {
        if (e.statusCode == 401) {
          await logout();
        }
        // statusCode lain (mis. server offline): pertahankan sesi lokal
      }
    }
    _initialized = true;
    notifyListeners();
  }

  Future<void> _saveUser(User user) async {
    await _prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    _loading = true;
    notifyListeners();
    try {
      final (user, token) = await _api.login(email: email, password: password);
      await _setSession(user, token);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    _loading = true;
    notifyListeners();
    try {
      final (user, token) = await _api.register(
        name: name,
        email: email,
        password: password,
        phone: phone,
      );
      await _setSession(user, token);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> _setSession(User user, String token) async {
    _user = user;
    _token = token;
    _api.token = token;
    await _prefs.setString(_tokenKey, token);
    await _saveUser(user);
  }

  Future<void> updateProfile({
    String? name,
    String? phone,
    String? password,
  }) async {
    final updated = await _api.updateProfile(
      name: name,
      phone: phone,
      password: password,
    );
    _user = updated;
    await _saveUser(updated);
    notifyListeners();
  }

  Future<void> logout() async {
    if (_token != null) {
      try {
        await _api.logout();
      } on ApiException {
        // token sudah tidak valid, tetap lanjut logout lokal
      }
    }
    _token = null;
    _user = null;
    _api.token = null;
    await _prefs.remove(_tokenKey);
    await _prefs.remove(_userKey);
    notifyListeners();
  }
}
