import 'dart:convert';

import 'package:http/http.dart' as http;
import '../config/app_urls.dart';
import '../utils/html_utils.dart';
import 'cache_service.dart';

class WpApiService {
  static const String fallbackAuthorName = 'The College View';
  static const String _authorInfoEndpoint = '${AppUrls.apiBase}/get-subheading';

  static final CacheService _cache = CacheService();

  static final Map<int, String> _mediaUrlMemoryCache = {};
  static final Map<String, String> _authorMemoryCache = {};

  static String? getCachedFeaturedMediaUrl(int mediaId) {
    if (mediaId <= 0) return null;
    return _mediaUrlMemoryCache[mediaId];
  }

  static void cacheFeaturedMediaUrl(int mediaId, String url) {
    if (mediaId > 0 && url.isNotEmpty) {
      _mediaUrlMemoryCache[mediaId] = url;
    }
  }

  static String? getCachedAuthorName(String articleUrl) {
    if (articleUrl.isEmpty) return null;
    return _authorMemoryCache[articleUrl];
  }

  static void cacheAuthorName(String articleUrl, String name) {
    if (articleUrl.isNotEmpty && name.isNotEmpty) {
      _authorMemoryCache[articleUrl] = name;
    }
  }

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
    String articleUrl, [
    int? authorId,
  ]) async {
    if (articleUrl.trim().isEmpty) {
      return fallbackAuthorName;
    }
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

              if (subheading is String && subheading.trim().isNotEmpty) {
                return subheading.trim();
              }
            } else if (decoded is String && decoded.trim().isNotEmpty) {
              return decoded.trim();
            }
          } catch (_) {
            if (!body.startsWith('{') && !body.startsWith('<')) {
              return body;
            }
          }
        }
      }
    } catch (_) {
      // Ignore errors and fall back below.
    }

    return fallbackAuthorName;
  }

  static Future<String> fetchAuthorName(
    String articleUrl, [
    int? authorId,
  ]) async {
    if (articleUrl.trim().isEmpty) {
      return fallbackAuthorName;
    }
    final cached = getCachedAuthorName(articleUrl);
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }
    try {
      final authorName = await fetchAuthorInfo(articleUrl, authorId);
      final decoded = HtmlUtils.decodeHtmlEntities(authorName).trim();
      final result = decoded.isNotEmpty ? decoded : fallbackAuthorName;
      cacheAuthorName(articleUrl, result);
      return result;
    } catch (_) {
      return fallbackAuthorName;
    }
  }

  static Future<String> fetchFeaturedMediaUrl(int mediaId) async {
    if (mediaId <= 0) return '';
    final cached = getCachedFeaturedMediaUrl(mediaId);
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }
    try {
      final response = await get(
        Uri.parse('${AppUrls.apiBase}/wp-json/wp/v2/media/$mediaId'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final url = data['source_url']?.toString() ?? '';
        if (url.isNotEmpty) {
          cacheFeaturedMediaUrl(mediaId, url);
        }
        return url;
      }
      return '';
    } catch (_) {
      return '';
    }
  }

  static Future<List<String>> fetchTagNames(List<int> tagIds) async {
    if (tagIds.isEmpty) return [];
    try {
      final url =
          '${AppUrls.apiBase}/wp-json/wp/v2/tags?include=${tagIds.join(',')}';
      final response = await get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        return data
            .map((item) => HtmlUtils.decodeHtmlEntities(item['name']))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }
}
