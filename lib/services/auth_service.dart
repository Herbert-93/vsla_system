import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'database_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Your Firebase Web API Key
  static const String _apiKey = 'AIzaSyAY-BGGZS21F4lRaDLSUNEDHd_6mo8sbJI';

  static const String _signInUrl =
      'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$_apiKey';
  static const String _signUpUrl =
      'https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$_apiKey';

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  String _toEmail(String umvaId) =>
      '${umvaId.toLowerCase().trim()}@vslaapp.com';

  String generateUmvaId(String firstName, String lastName) =>
      '${firstName.toLowerCase().trim()}.${lastName.toLowerCase().trim()}';

  Future<Map<String, dynamic>?> signInWithUmvaId(
      String umvaId, String password) async {
    final response = await http.post(
      Uri.parse(_signInUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': _toEmail(umvaId),
        'password': password,
        'returnSecureToken': true,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      final errorCode = data['error']['message'] as String? ?? 'UNKNOWN';
      throw FirebaseAuthError(errorCode);
    }

    final uid = data['localId'] as String;

    final db = await DatabaseService.instance.database;
    var results = await db.query('members', where: 'id = ?', whereArgs: [uid]);

    if (results.isEmpty) {
      results = await db.query('members',
          where: 'umvaId = ?', whereArgs: [umvaId.toLowerCase().trim()]);
      if (results.isNotEmpty) {
        await db.update('members', {'id': uid},
            where: 'umvaId = ?', whereArgs: [umvaId.toLowerCase().trim()]);
        results = await db.query('members', where: 'id = ?', whereArgs: [uid]);
      }
    }

    if (results.isEmpty) return null;

    final user = Map<String, dynamic>.from(results.first);

    await _saveSession(
      uid: uid,
      umvaId: umvaId.toLowerCase().trim(),
      groupId: user['groupId'] as String? ?? '',
      role: user['role'] as String? ?? 'member',
    );

    return {...user, 'id': uid};
  }

  Future<String> createFirebaseAccount({
    required String umvaId,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse(_signUpUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': _toEmail(umvaId),
        'password': password,
        'returnSecureToken': true,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      final errorCode = data['error']['message'] as String? ?? 'UNKNOWN';
      throw FirebaseAuthError(errorCode);
    }

    return data['localId'] as String;
  }

  Future<void> saveRegistrationSession({
    required String uid,
    required String umvaId,
    required String groupId,
    required String role,
  }) async {
    await _saveSession(uid: uid, umvaId: umvaId, groupId: groupId, role: role);
  }

  Future<void> signOut() async {
    await _storage.deleteAll();
  }

  Future<bool> isLoggedIn() async {
    final uid = await _storage.read(key: 'user_id');
    return uid != null && uid.isNotEmpty;
  }

  Future<String?> getCurrentUserId() async => _storage.read(key: 'user_id');

  Future<String?> getCurrentGroupId() async => _storage.read(key: 'group_id');

  Future<String?> getCurrentRole() async => _storage.read(key: 'role');

  Future<String?> getCurrentUmvaId() async => _storage.read(key: 'umva_id');

  Future<void> setSelectedBank(String bankName) async =>
      _storage.write(key: 'selected_bank', value: bankName);

  Future<String?> getSelectedBank() async =>
      _storage.read(key: 'selected_bank');

  Future<void> _saveSession({
    required String uid,
    required String umvaId,
    required String groupId,
    required String role,
  }) async {
    await _storage.write(key: 'user_id', value: uid);
    await _storage.write(key: 'umva_id', value: umvaId);
    await _storage.write(key: 'group_id', value: groupId);
    await _storage.write(key: 'role', value: role);
  }
}

class FirebaseAuthError implements Exception {
  final String code;
  FirebaseAuthError(this.code);

  String get message {
    switch (code) {
      case 'EMAIL_NOT_FOUND':
      case 'INVALID_LOGIN_CREDENTIALS':
        return 'Invalid UMVA ID or password.';
      case 'WRONG_PASSWORD':
        return 'Incorrect password. Please try again.';
      case 'EMAIL_EXISTS':
        return 'An account with this UMVA ID already exists. Please login instead.';
      case 'WEAK_PASSWORD : Password should be at least 6 characters':
        return 'Password must be at least 6 characters.';
      case 'TOO_MANY_ATTEMPTS_TRY_LATER':
        return 'Too many failed attempts. Please wait a moment.';
      case 'USER_DISABLED':
        return 'This account has been disabled.';
      default:
        return 'Error: $code';
    }
  }
}
