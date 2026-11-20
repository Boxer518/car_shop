import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/session_user.dart';
import '../repositories/salon_api.dart';
import 'access.dart';

class AuthNotifier extends ChangeNotifier {
  AuthNotifier({this._prefs, this._api});

  static const tokenKey = 'auth_token';
  static const userKey = 'auth_user';

  final SharedPreferences? _prefs;
  SalonApi? _api;
  Future<bool>? _refreshing;

  SessionUser? user;
  String? token;
  String? notice;

  bool get isAuthenticated => user != null && token != null;

  AppRole? get role => user?.role;

  void attach(SalonApi api) {
    _api = api;
    api.bind(user);
  }

  Future<void> restore() async {
    final storedToken = _prefs?.getString(tokenKey);
    final storedUser = SessionUser.decode(_prefs?.getString(userKey));
    if (storedToken == null || storedToken.isEmpty || storedUser == null) {
      return;
    }
    token = storedToken;
    user = storedUser;
    _api?.bind(user);
    final refreshed = await refresh();
    if (!refreshed) {
      await logout(reason: 'Сессия истекла. Войдите снова.');
    }
  }

  Future<void> login(String email, String password) async {
    final session = await _require().login(email.trim(), password);
    await _apply(session);
  }

  Future<void> register({
    required String email,
    required String password,
    required String fullName,
    required String phone,
  }) async {
    final session = await _require().register(
      email: email,
      password: password,
      fullName: fullName,
      phone: phone,
    );
    await _apply(session);
  }

  Future<bool> refresh() {
    final current = token;
    if (current == null || current.isEmpty) {
      return Future<bool>.value(false);
    }
    return _refreshing ??= _refresh(current)
        .whenComplete(() => _refreshing = null);
  }

  Future<void> logout({String? reason}) async {
    token = null;
    user = null;
    notice = reason;
    _api?.bind(null);
    await _prefs?.remove(tokenKey);
    await _prefs?.remove(userKey);
    notifyListeners();
  }

  void signInForTest(SessionUser next, {String token = 'memory:test'}) {
    user = next;
    this.token = token;
    _api?.bind(next);
    notifyListeners();
  }

  Future<void> _apply(AuthSession session) async {
    token = session.token;
    user = session.user;
    notice = null;
    _api?.bind(session.user);
    await _prefs?.setString(tokenKey, session.token);
    await _prefs?.setString(userKey, session.user.encode());
    notifyListeners();
  }

  Future<bool> _refresh(String current) async {
    try {
      final session = await _require().refresh(current);
      await _apply(session);
      return true;
    } on Exception {
      return false;
    }
  }

  SalonApi _require() {
    final api = _api;
    if (api == null) {
      throw StateError('API не подключён');
    }
    return api;
  }
}
