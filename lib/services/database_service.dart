import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/bylaw.dart';
import '../models/center_model.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null && _database!.isOpen) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'uecfi_portal.db');

    final file = File(path);
    bool shouldCopy = true;

    ByteData? data;
    try {
      data = await rootBundle.load('assets/db/uecfi_portal.db');
    } catch (e) {
      debugPrint('Error loading asset database: $e');
    }

    if (data != null && await file.exists()) {
      final existingSize = await file.length();
      final assetSize = data.lengthInBytes;

      // In debug mode or if asset size has changed, update with the latest asset database
      if (!kDebugMode && existingSize == assetSize) {
        shouldCopy = false;
      }
    }

    if (shouldCopy && data != null) {
      try {
        await Directory(dirname(path)).create(recursive: true);
      } catch (e) {
        debugPrint('Directory creation warning: $e');
      }

      try {
        final List<int> bytes =
            data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);

        await file.writeAsBytes(bytes, flush: true);
        debugPrint(
            'Database updated successfully to $path (size: ${bytes.length} bytes)');
      } catch (e) {
        debugPrint('Error writing asset database: $e');
      }
    }

    return await openDatabase(path);
  }

  Future<List<CenterModel>> getCenters({
    String? district,
    String? area,
    String? query,
  }) async {
    try {
      final db = await database;
      String whereClause = '';
      final List<dynamic> whereArgs = [];

      if (district != null &&
          district.isNotEmpty &&
          district != 'All' &&
          district != 'All Districts') {
        whereClause += 'district = ?';
        whereArgs.add(district);
      }

      if (area != null &&
          area.isNotEmpty &&
          area != 'All' &&
          area != 'All Areas') {
        if (whereClause.isNotEmpty) whereClause += ' AND ';
        whereClause += 'area = ?';
        whereArgs.add(area);
      }

      if (query != null && query.trim().isNotEmpty) {
        if (whereClause.isNotEmpty) whereClause += ' AND ';
        whereClause +=
            '(centername LIKE ? OR centeraddress LIKE ? OR area LIKE ?)';
        final searchPattern = '%${query.trim()}%';
        whereArgs.addAll([searchPattern, searchPattern, searchPattern]);
      }

      final List<Map<String, dynamic>> results = await db.query(
        'centers_list',
        where: whereClause.isEmpty ? null : whereClause,
        whereArgs: whereArgs.isEmpty ? null : whereArgs,
        orderBy: 'district ASC, area ASC, centername ASC',
      );

      return results.map((map) => CenterModel.fromMap(map)).toList();
    } catch (e) {
      debugPrint('DatabaseService getCenters error: $e');
      return [];
    }
  }

  Future<List<String>> getDistricts() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> results = await db.rawQuery(
        "SELECT DISTINCT district FROM centers_list WHERE district IS NOT NULL AND district != '' ORDER BY district ASC",
      );
      return results
          .map((row) => row['district']?.toString() ?? '')
          .where((d) => d.isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('DatabaseService getDistricts error: $e');
      return [];
    }
  }

  Future<List<String>> getAreas({String? district}) async {
    try {
      final db = await database;
      String query =
          "SELECT DISTINCT area FROM centers_list WHERE area IS NOT NULL AND area != ''";
      List<dynamic> args = [];
      if (district != null &&
          district.isNotEmpty &&
          district != 'All' &&
          district != 'All Districts') {
        query += " AND district = ?";
        args.add(district);
      }
      query += " ORDER BY area ASC";

      final List<Map<String, dynamic>> results = await db.rawQuery(query, args);
      return results
          .map((row) => row['area']?.toString() ?? '')
          .where((a) => a.isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('DatabaseService getAreas error: $e');
      return [];
    }
  }

  // ==========================================
  // BYLAWS (TABLE: bylaws_list)
  // ==========================================

  /// Retrieve all bylaws or filter by search query / chapter
  Future<List<Bylaw>> getBylaws({String? query, String? chapter}) async {
    try {
      final db = await database;

      String whereClause = '';
      final List<dynamic> whereArgs = [];

      if (chapter != null && chapter.isNotEmpty && chapter != 'All') {
        whereClause += 'bylaw_chapter = ?';
        whereArgs.add(chapter);
      }

      if (query != null && query.trim().isNotEmpty) {
        if (whereClause.isNotEmpty) whereClause += ' AND ';
        whereClause +=
            '(bylaw_title LIKE ? OR bylaw_content LIKE ? OR bylaw_chapter LIKE ?)';
        final searchPattern = '%${query.trim()}%';
        whereArgs.addAll([searchPattern, searchPattern, searchPattern]);
      }

      final List<Map<String, dynamic>> results = await db.query(
        'bylaws_list',
        where: whereClause.isEmpty ? null : whereClause,
        whereArgs: whereArgs.isEmpty ? null : whereArgs,
        orderBy: 'bylaw_chapter ASC, ROWID ASC',
      );

      return results.map((map) => Bylaw.fromMap(map)).toList();
    } catch (e) {
      debugPrint('DatabaseService getBylaws error: $e');
      return [];
    }
  }

  /// Retrieve distinct chapters available in bylaws_list
  Future<List<String>> getChapters() async {
    try {
      final db = await database;

      final List<Map<String, dynamic>> results = await db.rawQuery(
        'SELECT DISTINCT bylaw_chapter FROM bylaws_list ORDER BY bylaw_chapter ASC',
      );

      return results
          .map((row) => row['bylaw_chapter'] as String? ?? '')
          .where((chapter) => chapter.isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('DatabaseService getChapters error: $e');
      return [];
    }
  }
}

