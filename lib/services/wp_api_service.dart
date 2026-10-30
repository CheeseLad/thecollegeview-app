import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/article.dart';
import '../utils/html_utils.dart';
import 'cache_service.dart';

class WpApiService {
  static String get fallbackAuthorName => AppConfig.instance.fallbackAuthorName;
  static String get _authorInfoEndpoint =>
      '${AppConfig.instance.apiBase}/get-subheading';

  static final CacheService _cache = CacheService();
  static final http.Client _client = http.Client();

  /// Reactive indicator of whether the most recent network request failed and
  /// fell back to offline/cached mode.
  static final ValueNotifier<bool> isOffline = ValueNotifier<bool>(false);

  static final Map<int, String> _mediaUrlMemoryCache = {};
  static final Map<String, String> _authorMemoryCache = {};
  static final Map<int, String> _tagMemoryCache = {};

  static final Map<String, Future<http.Response>> _inFlightGetRequests = {};
  static final Map<String, Future<String>> _inFlightAuthorRequests = {};
  static final Map<int, Future<String>> _inFlightMediaRequests = {};

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

  static String? getInitialFeaturedMediaUrl(
    Article article, [
    String? overrideUrl,
  ]) {
    for (final candidate in [
      overrideUrl,
      article.embeddedFeaturedMediaUrl,
      getCachedFeaturedMediaUrl(article.featuredMedia),
    ]) {
      if (candidate != null && candidate.isNotEmpty) {
        return candidate;
      }
    }
    return null;
  }

  static String? getInitialAuthorName(
    Article article, [
    String? overrideName,
  ]) {
    for (final candidate in [
      overrideName,
      article.embeddedAuthorName,
      getCachedAuthorName(article.link),
    ]) {
      if (candidate != null && candidate.isNotEmpty) {
        return candidate;
      }
    }
    return null;
  }

  static List<String>? getInitialTagNames(
    List<int> tagIds, [
    List<String>? overrideTagNames,
  ]) {
    if (tagIds.isEmpty) return const [];
    if (overrideTagNames != null && overrideTagNames.isNotEmpty) {
      return overrideTagNames;
    }
    if (tagIds.every(_tagMemoryCache.containsKey)) {
      return tagIds.map((id) => _tagMemoryCache[id]!).toList();
    }
    return null;
  }

  static Future<String> resolveFeaturedMediaUrl(
    Article article, [
    String? overrideUrl,
  ]) async {
    final cached = getInitialFeaturedMediaUrl(article, overrideUrl);
    if (cached != null) return cached;
    if (article.featuredMedia <= 0) return '';
    return fetchFeaturedMediaUrl(article.featuredMedia);
  }

  static Future<String> resolveAuthorName(
    Article article, [
    String? overrideName,
  ]) async {
    final cached = getInitialAuthorName(article, overrideName);
    if (cached != null) return cached;
    return fetchAuthorName(article.link, article.author);
  }

  static Future<http.Response> get(
    Uri uri, {
    Map<String, String>? headers,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached = _cache.getCached(uri, allowStale: false);
      if (cached != null) {
        return cached;
      }
    }

    final canCoalesce = !forceRefresh && (headers == null || headers.isEmpty);
    final key = uri.toString();
    if (canCoalesce) {
      final inFlight = _inFlightGetRequests[key];
      if (inFlight != null) {
        return inFlight;
      }
    }

    final future = _performGet(uri, headers: headers);
    if (canCoalesce) {
      _inFlightGetRequests[key] = future;
    }
    try {
      return await future;
    } finally {
      if (canCoalesce) {
        _inFlightGetRequests.remove(key);
      }
    }
  }

  static Future<http.Response> _performGet(
    Uri uri, {
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _client
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 12));
      if (response.statusCode == 200) {
        if (isOffline.value) {
          isOffline.value = false;
        }
        await _cache.setCached(uri, response);
        return response;
      }

      // On server errors, fall back to stale cache if available
      if (response.statusCode >= 500) {
        final stale = _cache.getCached(uri, allowStale: true);
        if (stale != null) {
          isOffline.value = true;
          return stale;
        }
      }
      return response;
    } catch (_) {
      isOffline.value = true;
      final stale = _cache.getCached(uri, allowStale: true);
      if (stale != null) {
        return stale;
      }
      rethrow;
    }
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
    final trimmedUrl = articleUrl.trim();
    if (trimmedUrl.isEmpty) {
      return fallbackAuthorName;
    }
    final cached = getCachedAuthorName(trimmedUrl);
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }

    final inFlight = _inFlightAuthorRequests[trimmedUrl];
    if (inFlight != null) {
      return inFlight;
    }

    final future = () async {
      try {
        final authorName = await fetchAuthorInfo(trimmedUrl, authorId);
        final decoded = HtmlUtils.decodeHtmlEntities(authorName).trim();
        final result = decoded.isNotEmpty ? decoded : fallbackAuthorName;
        cacheAuthorName(trimmedUrl, result);
        return result;
      } catch (_) {
        return fallbackAuthorName;
      }
    }();

    _inFlightAuthorRequests[trimmedUrl] = future;
    try {
      return await future;
    } finally {
      _inFlightAuthorRequests.remove(trimmedUrl);
    }
  }

  static Future<String> fetchFeaturedMediaUrl(int mediaId) async {
    if (mediaId <= 0) return '';
    final cached = getCachedFeaturedMediaUrl(mediaId);
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }

    final inFlight = _inFlightMediaRequests[mediaId];
    if (inFlight != null) {
      return inFlight;
    }

    final future = () async {
      try {
        final response = await get(
          Uri.parse(
              '${AppConfig.instance.apiBase}/wp-json/wp/v2/media/$mediaId'),
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final url = data is Map
              ? (Article.extractPreferredMediaUrl(data) ?? '')
              : '';
          if (url.isNotEmpty) {
            cacheFeaturedMediaUrl(mediaId, url);
          }
          return url;
        }
        return '';
      } catch (_) {
        return '';
      }
    }();

    _inFlightMediaRequests[mediaId] = future;
    try {
      return await future;
    } finally {
      _inFlightMediaRequests.remove(mediaId);
    }
  }

  static Future<List<String>> fetchTagNames(List<int> tagIds) async {
    if (tagIds.isEmpty) return [];

    final missingIds =
        tagIds.where((id) => !_tagMemoryCache.containsKey(id)).toList();

    if (missingIds.isEmpty) {
      return tagIds
          .map((id) => _tagMemoryCache[id])
          .whereType<String>()
          .toList();
    }

    try {
      final url =
          '${AppConfig.instance.apiBase}/wp-json/wp/v2/tags?include=${missingIds.join(',')}&_fields=id,name';
      final response = await get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        for (final item in data.whereType<Map>()) {
          final id = int.tryParse(item['id']?.toString() ?? '0') ?? 0;
          final name =
              HtmlUtils.decodeHtmlEntities(item['name']?.toString() ?? '');
          if (id > 0 && name.isNotEmpty) {
            _tagMemoryCache[id] = name;
          }
        }
        final resolved = tagIds
            .map((id) => _tagMemoryCache[id])
            .whereType<String>()
            .toList();
        if (resolved.isNotEmpty) {
          return resolved;
        }
        return data
            .map((item) =>
                HtmlUtils.decodeHtmlEntities(item['name']?.toString() ?? ''))
            .where((name) => name.isNotEmpty)
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  static Future<String> fetchAboutHtml() async {
    try {
      final response = await get(
        Uri.parse(
            '${AppConfig.instance.apiBase}/wp-json/wp/v2/pages?slug=about'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List && data.isNotEmpty && data[0] is Map) {
          final rendered = data[0]['content']?['rendered']?.toString().trim();
          if (rendered != null && rendered.isNotEmpty) {
            return rendered;
          }
        }
      }
    } catch (_) {}
    return AppConfig.instance.aboutHtml;
  }
}
