import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';

class CacheService {
  static const String _boxName = 'apiCache';
  static const int _ttlMs = 3600000;
  static final CacheService _instance = CacheService._internal();
  late Box<Map> _box;

  factory CacheService() => _instance;
  CacheService._internal();

  Future<void> init() async {
    _box = await Hive.openBox<Map>(_boxName);
    _clearExpired();
  }

  http.Response? getCached(Uri uri) {
    final key = uri.toString();
    final entry = _box.get(key);

    if (entry == null) return null;

    final timestamp = entry['timestamp'] as int?;
    if (timestamp == null) {
      _box.delete(key);
      return null;
    }

    if (DateTime.now().millisecondsSinceEpoch - timestamp > _ttlMs) {
      _box.delete(key);
      return null;
    }

    final body = entry['body'] as String? ?? '';
    final statusCode = entry['statusCode'] as int? ?? 0;
    final headersMap = entry['headers'] as Map?;
    final headers = headersMap?.cast<String, String>() ?? <String, String>{};

    return http.Response(body, statusCode, headers: headers);
  }

  Future<void> setCached(Uri uri, http.Response response) async {
    final key = uri.toString();
    await _box.put(key, {
      'body': response.body,
      'statusCode': response.statusCode,
      'headers': response.headers,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> _clearExpired() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final keysToDelete = <String>[];

    for (final key in _box.keys) {
      final entry = _box.get(key);
      if (entry == null) continue;

      final timestamp = entry['timestamp'] as int?;
      if (timestamp == null || now - timestamp > _ttlMs) {
        keysToDelete.add(key as String);
      }
    }

    for (final key in keysToDelete) {
      await _box.delete(key);
    }
  }

  Future<void> clear() async {
    await _box.clear();
  }
}
