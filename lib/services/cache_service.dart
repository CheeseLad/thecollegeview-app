import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';
import '../config/app_config.dart';

class CacheService {
  static const String _boxName = 'apiCache';
  static int get _freshTtlMs => AppConfig.instance.freshCacheTtlMs;
  static int get _maxStaleTtlMs => AppConfig.instance.staleCacheTtlMs;
  static int get _maxEntries => AppConfig.instance.maxCacheEntries;
  static final CacheService _instance = CacheService._internal();
  late Box<Map> _box;

  factory CacheService() => _instance;
  CacheService._internal();

  static Future<Box<T>> openBoxWithRecovery<T>(String name) async {
    try {
      return await Hive.openBox<T>(name);
    } catch (_) {
      await Hive.deleteBoxFromDisk(name);
      return await Hive.openBox<T>(name);
    }
  }

  Future<void> init() async {
    _box = await openBoxWithRecovery<Map>(_boxName);
    _clearExpired();
  }

  http.Response? getCached(Uri uri, {bool allowStale = false}) {
    if (!_box.isOpen) return null;
    final key = uri.toString();
    final entry = _box.get(key);

    if (entry == null) return null;

    final timestamp = entry['timestamp'] as int?;
    if (timestamp == null) {
      _box.delete(key);
      return null;
    }

    final ageMs = DateTime.now().millisecondsSinceEpoch - timestamp;
    if (ageMs > _maxStaleTtlMs) {
      _box.delete(key);
      return null;
    }

    if (!allowStale && ageMs > _freshTtlMs) {
      return null;
    }

    final body = entry['body'] as String? ?? '';
    final statusCode = entry['statusCode'] as int? ?? 0;
    final headersMap = entry['headers'] as Map?;
    final headers = <String, String>{
      ...(headersMap?.cast<String, String>() ?? <String, String>{}),
      if (ageMs > _freshTtlMs) 'x-cache-stale': 'true',
    };

    return http.Response(body, statusCode, headers: headers);
  }

  Future<void> setCached(Uri uri, http.Response response) async {
    if (!_box.isOpen || response.statusCode != 200) return;
    final key = uri.toString();
    await _box.put(key, {
      'body': response.body,
      'statusCode': response.statusCode,
      'headers': response.headers,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    if (_box.length > _maxEntries) {
      await _evictOldestEntries();
    }
  }

  Future<void> _clearExpired() async {
    if (!_box.isOpen) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    final keysToDelete = <dynamic>[];

    for (final key in _box.keys) {
      final entry = _box.get(key);
      if (entry == null) continue;

      final timestamp = entry['timestamp'] as int?;
      if (timestamp == null || now - timestamp > _maxStaleTtlMs) {
        keysToDelete.add(key);
      }
    }

    if (keysToDelete.isNotEmpty) {
      await _box.deleteAll(keysToDelete);
    }

    if (_box.length > _maxEntries) {
      await _evictOldestEntries();
    }
  }

  Future<void> _evictOldestEntries() async {
    if (!_box.isOpen || _box.length <= _maxEntries) return;
    final entriesWithTimestamp = <({dynamic key, int timestamp})>[];
    for (final key in _box.keys) {
      final entry = _box.get(key);
      final ts = (entry?['timestamp'] as int?) ?? 0;
      entriesWithTimestamp.add((key: key, timestamp: ts));
    }
    entriesWithTimestamp.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final excessCount = entriesWithTimestamp.length - _maxEntries;
    if (excessCount > 0) {
      await _box.deleteAll(
        entriesWithTimestamp.take(excessCount).map((e) => e.key),
      );
    }
  }

  Future<void> clear() async {
    if (_box.isOpen) {
      await _box.clear();
    }
  }
}
