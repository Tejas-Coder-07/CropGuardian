// Crop Guardian - local SQLite store for offline-first data
// Author: Tejas S <tejus.sgowda07@gmail.com>
// Team Maverick - Cambridge Institute of Engineering

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalDatabase {
  static final LocalDatabase instance = LocalDatabase._();
  LocalDatabase._();

  static Database? _db;

  Future<Database> get database async {
    _db ??= await _init();
    return _db!;
  }

  Future<Database> _init() async {
    final path = join(await getDatabasesPath(), 'crop_guardian.db');
    return openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE scans (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId TEXT,
        imagePath TEXT NOT NULL,
        cropType TEXT,
        detectedIssue TEXT,
        severity TEXT,
        confidence REAL,
        source TEXT NOT NULL,
        payload TEXT,
        farmerConfirmed INTEGER DEFAULT 0,
        correctedLabel TEXT,
        syncedToCloud INTEGER DEFAULT 0,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE advisory_cache (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cacheKey TEXT NOT NULL UNIQUE,
        payload TEXT NOT NULL,
        fetchedAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId TEXT,
        category TEXT NOT NULL,
        note TEXT,
        amount REAL NOT NULL,
        spentOn TEXT NOT NULL,
        syncedToCloud INTEGER DEFAULT 0,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('CREATE INDEX idx_scans_synced ON scans(syncedToCloud)');
    await db.execute('CREATE INDEX idx_scans_created ON scans(createdAt)');
  }

  // ---------- scans ----------

  Future<int> insertScan(Map<String, dynamic> row) async {
    final db = await database;
    return db.insert('scans', row);
  }

  Future<List<Map<String, dynamic>>> recentScans({int limit = 50}) async {
    final db = await database;
    return db.query('scans', orderBy: 'createdAt DESC', limit: limit);
  }

  Future<List<Map<String, dynamic>>> unsyncedScans() async {
    final db = await database;
    return db.query('scans', where: 'syncedToCloud = 0');
  }

  Future<int> markScanSynced(int id) async {
    final db = await database;
    return db.update('scans', {'syncedToCloud': 1},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<int> confirmScan(int id, {String? correctedLabel}) async {
    final db = await database;
    return db.update(
      'scans',
      {
        'farmerConfirmed': 1,
        'correctedLabel': correctedLabel,
        'syncedToCloud': 0,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ---------- advisory cache ----------

  Future<void> cacheAdvisory(String key, String payload) async {
    final db = await database;
    await db.insert(
      'advisory_cache',
      {
        'cacheKey': key,
        'payload': payload,
        'fetchedAt': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> readAdvisory(String key,
      {Duration maxAge = const Duration(hours: 12)}) async {
    final db = await database;
    final rows = await db.query('advisory_cache',
        where: 'cacheKey = ?', whereArgs: [key], limit: 1);
    if (rows.isEmpty) return null;

    final fetchedAt = DateTime.parse(rows.first['fetchedAt'] as String);
    if (DateTime.now().difference(fetchedAt) > maxAge) return null;
    return rows.first;
  }

  // ---------- expenses ----------

  Future<int> insertExpense(Map<String, dynamic> row) async {
    final db = await database;
    return db.insert('expenses', row);
  }

  Future<List<Map<String, dynamic>>> expenses({int limit = 200}) async {
    final db = await database;
    return db.query('expenses', orderBy: 'spentOn DESC', limit: limit);
  }

  Future<double> totalSpend() async {
    final db = await database;
    final result = await db.rawQuery('SELECT SUM(amount) AS total FROM expenses');
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }
}