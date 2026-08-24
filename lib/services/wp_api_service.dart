import 'dart:convert';

import 'package:http/http.dart' as http;
import '../config/app_urls.dart';
import 'cache_service.dart';

class WpApiService {
  static const String _authorInfoEndpoint =
      '${AppUrls.apiBase}/get-subheading';

  static final CacheService _cache = CacheService();

  static Future<http.Response> get(
    Uri uri, {
    Map<String, String>? headers,
  }) async {
    final cached = _cache.getCached(uri);
    if (cached != null) {
      return cached;
    }

    final response = await http.get(uri, headers: headers);
    if (response.statusCode == 200) {
      await _cache.setCached(uri, response);
    }
    return response;
  }

  static Future<String> fetchAuthorInfo(
    String articleUrl,
    int authorId,
  ) async {
    try {
      final response = await get(
        Uri.parse(_authorInfoEndpoint).replace(
          queryParameters: {'url': articleUrl},
        ),
      );

      if (response.statusCode == 200) {
        final body = response.body.trim();

        if (body.isNotEmpty) {
          try {
            final decoded = jsonDecode(body);

            if (decoded is Map<String, dynamic>) {
              final subheading = decoded['subheading'];

              if (subheading is String &&
                  subheading.trim().isNotEmpty) {
                return subheading.trim();
              }
            }
          } catch (_) {
            return body;
          }

          return body;
        }
      }
    } catch (_) {
      // Ignore errors and throw below.
    }

    throw Exception('Failed to load author subheading');
  }
}