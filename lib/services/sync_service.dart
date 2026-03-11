import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';
import '../services/auth_service.dart';
import 'database_service.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  static const String _baseUrl = 'https://your-vsla-api.com';

  final DatabaseService _dbService = DatabaseService.instance;
  final AuthService _authService = AuthService();

  Future<bool> isOnline() async {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }

  Future<void> syncData({String? groupId}) async {
    if (!await isOnline()) throw Exception('No internet connection');

    try {
      // prefer provided groupId; avoid calling a missing AuthService.getGroupId()
      final gid = groupId;
      if (gid == null) throw Exception('No group selected');

      final db = await _dbService.database;

      // Sync unsynced groups
      final groups =
          await db.query('groups', where: 'isSynced = ?', whereArgs: [0]);
      for (final group in groups) {
        await _postToServer('/sync/groups', group);
        await db.update('groups', {'isSynced': 1},
            where: 'id = ?', whereArgs: [group['id']]);
      }

      // Sync unsynced members
      final members =
          await db.query('members', where: 'isSynced = ?', whereArgs: [0]);
      for (final member in members) {
        await _postToServer('/sync/members', member);
        await db.update('members', {'isSynced': 1},
            where: 'id = ?', whereArgs: [member['id']]);
      }

      // Sync unsynced meetings
      final meetings =
          await db.query('meetings', where: 'isSynced = ?', whereArgs: [0]);
      for (final meeting in meetings) {
        await _postToServer('/sync/meetings', meeting);
        await db.update('meetings', {'isSynced': 1},
            where: 'id = ?', whereArgs: [meeting['id']]);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _postToServer(String endpoint, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$_baseUrl$endpoint'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Server error ${response.statusCode}: ${response.body}');
    }
  }

  Future<void> downloadGroupData(String groupId) async {
    if (!await isOnline()) throw Exception('No internet connection');

    try {
      // Download group
      final groupRes = await http.get(Uri.parse('$_baseUrl/groups/$groupId'));
      if (groupRes.statusCode == 200) {
        final groupData = json.decode(groupRes.body) as Map<String, dynamic>;
        final db = await _dbService.database;
        await db.insert('groups', {...groupData, 'isSynced': 1},
            conflictAlgorithm: ConflictAlgorithm.replace);
      }

      // Download members
      final membersRes =
          await http.get(Uri.parse('$_baseUrl/groups/$groupId/members'));
      if (membersRes.statusCode == 200) {
        final membersData = json.decode(membersRes.body) as List<dynamic>;
        final db = await _dbService.database;
        for (final member in membersData) {
          await db.insert(
              'members', {...(member as Map<String, dynamic>), 'isSynced': 1},
              conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }
    } catch (e) {
      rethrow;
    }
  }
}
