import 'dart:convert';
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../models/member.dart';
import '../models/group.dart';
import '../models/settings.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('vsla.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final String dbPath;

    if (Platform.isWindows) {
      // Windows: save to current user's Desktop
      final String userProfile =
          Platform.environment['USERPROFILE'] ?? 'C:\\Users\\Public';
      dbPath = join(userProfile, 'Desktop', filePath);
    } else if (Platform.isLinux) {
      // Linux: save to Desktop
      final String home = Platform.environment['HOME'] ?? '/home';
      dbPath = join(home, 'Desktop', filePath);
    } else {
      // Fallback for any other platform
      final documentsDirectory = await getApplicationSupportDirectory();
      dbPath = join(documentsDirectory.path, filePath);
    }

    // Make sure the folder exists
    await Directory(dirname(dbPath)).create(recursive: true);

    return await databaseFactoryFfi.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 3,
        onCreate: _createDB,
        onUpgrade: _onUpgrade,
      ),
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE groups(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        groupCode TEXT UNIQUE NOT NULL,
        bankName TEXT NOT NULL,
        formationDate TEXT NOT NULL,
        presidentId TEXT DEFAULT '',
        treasurerId TEXT DEFAULT '',
        secretaryId TEXT DEFAULT '',
        totalMembers INTEGER DEFAULT 0,
        totalSavings REAL DEFAULT 0,
        totalLoanOutstanding REAL DEFAULT 0,
        socialFundBalance REAL DEFAULT 0,
        isActive INTEGER DEFAULT 1,
        cycleStartDate TEXT,
        cycleDuration INTEGER DEFAULT 52,
        currentMeeting INTEGER DEFAULT 0,
        isSynced INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE members(
        id TEXT PRIMARY KEY,
        umvaId TEXT UNIQUE NOT NULL,
        firstName TEXT NOT NULL,
        lastName TEXT NOT NULL,
        gender TEXT NOT NULL,
        phone TEXT DEFAULT '',
        address TEXT DEFAULT '',
        region TEXT DEFAULT '',
        district TEXT DEFAULT '',
        constituency TEXT DEFAULT '',
        subCounty TEXT DEFAULT '',
        groupId TEXT NOT NULL,
        role TEXT DEFAULT 'member',
        savingsBalance REAL DEFAULT 0,
        loanBalance REAL DEFAULT 0,
        socialFundBalance REAL DEFAULT 0,
        isActive INTEGER DEFAULT 1,
        registrationDate TEXT NOT NULL,
        passwordHash TEXT DEFAULT '',
        isSynced INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE settings(
        id TEXT PRIMARY KEY,
        groupId TEXT UNIQUE NOT NULL,
        shareValue REAL NOT NULL,
        minShareUnits INTEGER DEFAULT 1,
        maxShareUnits INTEGER DEFAULT 5,
        minSocialFundAmount REAL NOT NULL,
        solidarityFundCompulsory INTEGER DEFAULT 1,
        interestRate REAL DEFAULT 30,
        maxLoanMultiplier INTEGER DEFAULT 3,
        minLoanPeriod INTEGER DEFAULT 4,
        maxLoanPeriod INTEGER DEFAULT 12,
        enablePenalties INTEGER DEFAULT 1,
        updatedAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE meetings(
        id TEXT PRIMARY KEY,
        groupId TEXT NOT NULL,
        meetingNumber INTEGER NOT NULL,
        date TEXT NOT NULL,
        attendance TEXT DEFAULT '{}',
        socialFundCollections TEXT DEFAULT '{}',
        socialFundDistributions TEXT DEFAULT '{}',
        savings TEXT DEFAULT '{}',
        loanRequests TEXT DEFAULT '[]',
        loanRepayments TEXT DEFAULT '[]',
        penalties TEXT DEFAULT '[]',
        totalSavings REAL DEFAULT 0,
        totalSocialFund REAL DEFAULT 0,
        totalLoans REAL DEFAULT 0,
        totalPenalties REAL DEFAULT 0,
        status TEXT DEFAULT 'in_progress',
        notes TEXT DEFAULT '',
        verifiedByPresident INTEGER DEFAULT 0,
        verifiedByTreasurer INTEGER DEFAULT 0,
        verifiedBySecretary INTEGER DEFAULT 0,
        createdAt TEXT NOT NULL,
        isSynced INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions(
        id TEXT PRIMARY KEY,
        groupId TEXT NOT NULL,
        memberId TEXT NOT NULL,
        meetingId TEXT DEFAULT '',
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        description TEXT,
        date TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE loans(
        id TEXT PRIMARY KEY,
        memberId TEXT NOT NULL,
        groupId TEXT NOT NULL,
        meetingId TEXT DEFAULT '',
        amount REAL NOT NULL,
        interestRate REAL NOT NULL,
        totalPayable REAL NOT NULL,
        paidAmount REAL DEFAULT 0,
        period INTEGER NOT NULL,
        startDate TEXT NOT NULL,
        dueDate TEXT NOT NULL,
        status TEXT DEFAULT 'active'
      )
    ''');

    await db.execute('''
      CREATE TABLE penalties(
        id TEXT PRIMARY KEY,
        memberId TEXT NOT NULL,
        groupId TEXT NOT NULL,
        meetingId TEXT DEFAULT '',
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        description TEXT,
        paid INTEGER DEFAULT 0,
        date TEXT NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add isSynced and new columns if upgrading
      try {
        await db.execute(
            'ALTER TABLE groups ADD COLUMN isSynced INTEGER DEFAULT 0');
      } catch (_) {}
      try {
        await db.execute(
            'ALTER TABLE members ADD COLUMN isSynced INTEGER DEFAULT 0');
      } catch (_) {}
      try {
        await db.execute(
            'ALTER TABLE members ADD COLUMN passwordHash TEXT DEFAULT \'\'');
      } catch (_) {}
      try {
        await db.execute(
            'ALTER TABLE meetings ADD COLUMN isSynced INTEGER DEFAULT 0');
      } catch (_) {}
      try {
        await db.execute(
            'ALTER TABLE meetings ADD COLUMN socialFundCollections TEXT DEFAULT \'{}\'');
      } catch (_) {}
      try {
        await db.execute(
            'ALTER TABLE meetings ADD COLUMN socialFundDistributions TEXT DEFAULT \'{}\'');
      } catch (_) {}
      try {
        await db.execute(
            'ALTER TABLE meetings ADD COLUMN savings TEXT DEFAULT \'{}\'');
      } catch (_) {}
      try {
        await db.execute(
            'ALTER TABLE meetings ADD COLUMN loanRequests TEXT DEFAULT \'[]\'');
      } catch (_) {}
      try {
        await db.execute(
            'ALTER TABLE meetings ADD COLUMN loanRepayments TEXT DEFAULT \'[]\'');
      } catch (_) {}
      try {
        await db.execute(
            'ALTER TABLE meetings ADD COLUMN penalties TEXT DEFAULT \'[]\'');
      } catch (_) {}
    }
  }

  Future<void> initializeDatabase() async {
    await database;
  }

  // ─── Member CRUD ────────────────────────────────────────────────────────────

  Future<String> insertMember(Member member) async {
    final db = await database;
    await db.insert('members', member.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    return member.id!;
  }

  Future<Map<String, dynamic>?> getMemberByUmvaId(String umvaId) async {
    final db = await database;
    final maps = await db.query(
      'members',
      where: 'umvaId = ?',
      whereArgs: [umvaId.toLowerCase().trim()],
    );
    if (maps.isNotEmpty) return Map<String, dynamic>.from(maps.first);
    return null;
  }

  Future<Member?> getMember(String id) async {
    final db = await database;
    final maps = await db.query('members', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) return Member.fromMap(maps.first);
    return null;
  }

  Future<List<Member>> getGroupMembers(String groupId) async {
    final db = await database;
    final maps = await db.query(
      'members',
      where: 'groupId = ? AND isActive = 1',
      whereArgs: [groupId],
      orderBy: 'firstName ASC',
    );
    return maps.map((m) => Member.fromMap(m)).toList();
  }

  Future<int> updateMember(Member member) async {
    final db = await database;
    return await db.update('members', member.toMap(),
        where: 'id = ?', whereArgs: [member.id]);
  }

  Future<int> setMemberPassword(String memberId, String passwordHash) async {
    final db = await database;
    return await db.update(
      'members',
      {'passwordHash': passwordHash},
      where: 'id = ?',
      whereArgs: [memberId],
    );
  }

  // ─── Group CRUD ─────────────────────────────────────────────────────────────

  Future<String> insertGroup(Group group) async {
    final db = await database;
    await db.insert('groups', group.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    return group.id!;
  }

  Future<Group?> getGroup(String id) async {
    final db = await database;
    final maps = await db.query('groups', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) return Group.fromMap(maps.first);
    return null;
  }

  Future<List<Group>> getAllGroups() async {
    final db = await database;
    final maps = await db.query('groups', where: 'isActive = 1');
    return maps.map((m) => Group.fromMap(m)).toList();
  }

  Future<int> updateGroup(Group group) async {
    final db = await database;
    return await db.update('groups', group.toMap(),
        where: 'id = ?', whereArgs: [group.id]);
  }

  // ─── Settings CRUD ──────────────────────────────────────────────────────────

  Future<String> insertSettings(GroupSettings settings) async {
    final db = await database;
    await db.insert('settings', settings.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    return settings.id!;
  }

  Future<GroupSettings?> getGroupSettings(String groupId) async {
    final db = await database;
    final maps =
        await db.query('settings', where: 'groupId = ?', whereArgs: [groupId]);
    if (maps.isNotEmpty) return GroupSettings.fromMap(maps.first);
    return null;
  }

  Future<int> updateSettings(GroupSettings settings) async {
    final db = await database;
    return await db.update('settings', settings.toMap(),
        where: 'groupId = ?', whereArgs: [settings.groupId]);
  }

  // ─── Meeting CRUD ───────────────────────────────────────────────────────────

  /// Convert a meeting data map (with complex nested objects) to a DB-safe map.
  Map<String, dynamic> _meetingToDbMap(Map<String, dynamic> meeting) {
    Object? encode(dynamic v) {
      if (v == null) return null;
      if (v is String || v is int || v is double) return v;
      return json.encode(v);
    }

    return {
      'id': meeting['id'],
      'groupId': meeting['groupId'],
      'meetingNumber': meeting['meetingNumber'],
      'date': meeting['date'],
      'attendance': encode(meeting['attendance']) ?? '{}',
      'socialFundCollections': encode(meeting['socialFundCollections']) ?? '{}',
      'socialFundDistributions':
          encode(meeting['socialFundDistributions']) ?? '{}',
      'savings': encode(meeting['savings']) ?? '{}',
      'loanRequests': encode(meeting['loanRequests']) ?? '[]',
      'loanRepayments': encode(meeting['loanRepayments']) ?? '[]',
      'penalties': encode(meeting['penalties']) ?? '[]',
      'totalSavings': (meeting['totalSavings'] as num?)?.toDouble() ?? 0.0,
      'totalSocialFund':
          (meeting['totalSocialFund'] as num?)?.toDouble() ?? 0.0,
      'totalLoans': (meeting['totalLoans'] as num?)?.toDouble() ?? 0.0,
      'totalPenalties': (meeting['totalPenalties'] as num?)?.toDouble() ?? 0.0,
      'status': meeting['status'] ?? 'in_progress',
      'notes': meeting['notes'] ?? '',
      'verifiedByPresident': meeting['verifiedByPresident'] ?? 0,
      'verifiedByTreasurer': meeting['verifiedByTreasurer'] ?? 0,
      'verifiedBySecretary': meeting['verifiedBySecretary'] ?? 0,
      'createdAt': meeting['createdAt'],
      'isSynced': meeting['isSynced'] ?? 0,
    };
  }

  Future<String> insertMeeting(Map<String, dynamic> meeting) async {
    final db = await database;
    await db.insert('meetings', _meetingToDbMap(meeting),
        conflictAlgorithm: ConflictAlgorithm.replace);
    return meeting['id'];
  }

  Future<int> updateMeeting(Map<String, dynamic> meeting) async {
    final db = await database;
    return await db.update('meetings', _meetingToDbMap(meeting),
        where: 'id = ?', whereArgs: [meeting['id']]);
  }

  Future<List<Map<String, dynamic>>> getGroupMeetings(String groupId) async {
    final db = await database;
    return await db.query(
      'meetings',
      where: 'groupId = ?',
      whereArgs: [groupId],
      orderBy: 'meetingNumber DESC',
    );
  }

  // ─── Transaction CRUD ───────────────────────────────────────────────────────

  Future<String> insertTransaction(Map<String, dynamic> transaction) async {
    final db = await database;
    await db.insert('transactions', transaction,
        conflictAlgorithm: ConflictAlgorithm.replace);
    return transaction['id'];
  }

  Future<List<Map<String, dynamic>>> getGroupTransactions(
      String groupId) async {
    final db = await database;
    return await db.query(
      'transactions',
      where: 'groupId = ?',
      whereArgs: [groupId],
      orderBy: 'date DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getMemberTransactions(
      String memberId) async {
    final db = await database;
    return await db.query(
      'transactions',
      where: 'memberId = ?',
      whereArgs: [memberId],
      orderBy: 'date DESC',
      limit: 20,
    );
  }

  // ─── Loan CRUD ──────────────────────────────────────────────────────────────

  Future<String> insertLoan(Map<String, dynamic> loan) async {
    final db = await database;
    await db.insert('loans', loan,
        conflictAlgorithm: ConflictAlgorithm.replace);
    return loan['id'];
  }

  Future<List<Map<String, dynamic>>> getMemberLoans(String memberId) async {
    final db = await database;
    return await db.query('loans',
        where: 'memberId = ?',
        whereArgs: [memberId],
        orderBy: 'startDate DESC');
  }

  Future<List<Map<String, dynamic>>> getGroupActiveLoans(String groupId) async {
    final db = await database;
    return await db.query('loans',
        where: 'groupId = ? AND status = ?', whereArgs: [groupId, 'active']);
  }

  Future<int> updateLoan(Map<String, dynamic> loan) async {
    final db = await database;
    return await db
        .update('loans', loan, where: 'id = ?', whereArgs: [loan['id']]);
  }

  // ─── Backup / Restore ───────────────────────────────────────────────────────

  Future<void> backupDatabase(String path) async {
    final documentsDirectory = await getApplicationSupportDirectory();
    final sourcePath = join(documentsDirectory.path, 'vsla.db');
    await File(sourcePath).copy(path);
  }

  Future<void> restoreDatabase(String path) async {
    final documentsDirectory = await getApplicationSupportDirectory();
    final destPath = join(documentsDirectory.path, 'vsla.db');
    await File(path).copy(destPath);
    _database = null;
    await database;
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
