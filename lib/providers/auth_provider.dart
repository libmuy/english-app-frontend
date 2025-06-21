import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:libmuyenglish/utils/errors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:simple_logging/simple_logging.dart';
import '../domain/global.dart';
import 'service_locator.dart';
import 'setting_provider.dart';

const _kExpiryDuration = Duration(days: 60);

final _log = Logger('LearningProvider', level: LogLevel.debug);

class AuthProvider {
  final ValueNotifier<bool> _isLoggedInNotifier = ValueNotifier<bool>(false);
  ValueNotifier<bool> get isLoggedInNotifier => _isLoggedInNotifier;
  String? _token;
  String? _email;
  String? _userName;
  String? _nonce;
  DateTime? _expiryDate;

  String get token {
    if (_token == null) throw NotLoginError();
    return _token!;
  }
  String? get email => _email;
  String? get userName => _userName;
  bool get isLoggedIn => _isLoggedInNotifier.value;
  bool get isAdmin => true;
  

  Future<void> _saveToPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', _token ?? '');
    await prefs.setString('userName', _userName ?? '');
    await prefs.setString('email', _email ?? '');
    await prefs.setString('nonce', _nonce ?? '');
    await prefs.setString('expiryDate', _expiryDate?.toIso8601String() ?? '');
  }

  Future<void> _loadFromPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    _userName = prefs.getString('userName');
    _email = prefs.getString('email');
    _nonce = prefs.getString('nonce');
    final expiryDateString = prefs.getString('expiryDate');
    if (expiryDateString != null && expiryDateString.isNotEmpty) {
      _expiryDate = DateTime.parse(expiryDateString);
    }

    _isLoggedInNotifier.value = _token != null;

    if (_isLoggedInNotifier.value) {
      final settingProvider = getIt<SettingProvider>();
      await settingProvider.loadSettings();
    }
    _log.info('AuthProvider loaded from preferences: '
        'isLoggedIn: $_isLoggedInNotifier, token: $_token, '
        'userName: $_userName, email: $_email, expiryDate: $_expiryDate');
  }

  Future<void> login(String usernName, String password) async {
    var resp = await http.post(
      Uri.parse('$kUrlPrefix/user/nonce.php'),
      body: jsonEncode({'user_name': usernName}),
      headers: {'Content-Type': 'application/json'},
    );
    final nonceJson = json.decode(resp.body) ?? {};

    if (resp.statusCode != 200) {
      throw HttpStatusError('Get Nonce', resp.statusCode,
          error: nonceJson['error']);
    }

    _nonce = nonceJson['nonce'] ?? '';
    var hashed = sha256.convert(utf8.encode(password)).toString();
    hashed = sha256.convert(utf8.encode(hashed + _nonce!)).toString();
    resp = await http.post(
      Uri.parse('$kUrlPrefix/user/login.php'),
      body: jsonEncode({'user_name': usernName, 'password': hashed}),
      headers: {'Content-Type': 'application/json'},
    );

    final data = jsonDecode(resp.body);
    if (resp.statusCode != 200) {
      throw HttpStatusError('Login', resp.statusCode,
          error: data['error']);
    }
    _userName = userName;
    _token = data['token'];
    _email = data['email'];
    _userName = data['user_name'];
    _expiryDate = DateTime.now().add(_kExpiryDuration);
    await _saveToPreferences();
    _isLoggedInNotifier.value = true;
    final settingProvider = getIt<SettingProvider>();
    await settingProvider.loadSettings();
  }

  Future<void> register(String username, String password, String email) async {
    final resp = await http.post(
      Uri.parse('$kUrlPrefix/user/register.php'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'user_name': username,
        'password': password,
        'email': email,
      }),
    );

    final data = jsonDecode(resp.body);
    if (resp.statusCode != 200) {
      throw HttpStatusError('Register', resp.statusCode, error: data['error']);
    }

    _token = data['token'];
    _email = data['email'];
    _userName = data['user_name'];
    _expiryDate = DateTime.now().add(_kExpiryDuration);
    await _saveToPreferences();
    _isLoggedInNotifier.value = true;

    
    getIt<SettingProvider>().saveSettings(forceAll: true);
  }

  Future<void> updateUser(String newPasswod, String newEmail) async {
    final resp = await http.post(
      Uri.parse('$kUrlPrefix/user/update.php'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(<String, String>{
        'user_name': _userName!,
        'password': newPasswod,
        'email': newEmail,
      }),
    );

    final data = jsonDecode(resp.body);
    if (resp.statusCode != 200) {
      throw HttpStatusError('Update user', resp.statusCode,
          error: data['error']);
    }
    _email = newEmail;
    await _saveToPreferences();
  }

  Future<void> loadToken() async {
    _loadFromPreferences();
  }

  Future<void> logout() async {
    _token = null;
    _email = null;
    _userName = null;
    _expiryDate = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('userId');
    await prefs.remove('email');
    await prefs.remove('nonce');
    await prefs.remove('expiryDate');
    _isLoggedInNotifier.value = false;
    _log.info('Logged out successfully');
  }
}
