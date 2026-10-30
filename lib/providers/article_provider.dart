import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart' hide Category;
import '../config/app_config.dart';
import '../config/category_config.dart';
import '../models/article.dart';
import '../models/category.dart';
import '../services/wp_api_service.dart';

List<Article> _parseArticlesFromJsonBody(String responseBody) {
  final data = json.decode(responseBody);
  if (data is List) {
    return data
        .whereType<Map<String, dynamic>>()
        .map(Article.fromJson)
        .toList();
  }
  return [];
}

class ArticleProvider with ChangeNotifier {
  static const String _postFields =
      'id,date,title,content,link,author,featured_media,tags,_links,_embedded';
  static const String _postEmbed = 'wp:featuredmedia';

  List<Article> _articles = [];
  List<Category> _categories = [];
  bool _loading = false;
  String? _error;
  int _currentPage = 1;
  int _totalPages = 1;
  int? _selectedCategory;
  int _fetchGeneration = 0;

  List<Article> get articles => _articles;
  List<Category> get categories => _categories;
  bool get loading => _loading;
  String? get error => _error;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int? get selectedCategory => _selectedCategory;

  ArticleProvider() {
    fetchCategories();
    fetchArticles();
  }

  Uri _buildPostsUri(Map<String, String> queryParameters, {int? postId}) {
    final path = postId != null
        ? '/wp-json/wp/v2/posts/$postId'
        : '/wp-json/wp/v2/posts';
    return Uri.parse('${AppConfig.instance.apiBase}$path').replace(
      queryParameters: {
        '_fields': _postFields,
        '_embed': _postEmbed,
        ...queryParameters,
      },
    );
  }

  Future<List<Article>> _decodeArticles(String body) async {
    final articles = await compute(_parseArticlesFromJsonBody, body);
    for (final article in articles) {
      final mediaUrl = article.embeddedFeaturedMediaUrl;
      if (mediaUrl != null &&
          mediaUrl.isNotEmpty &&
          article.featuredMedia > 0) {
        WpApiService.cacheFeaturedMediaUrl(article.featuredMedia, mediaUrl);
      }
    }
    return articles;
  }

  Future<List<Article>> _fetchPostsList(
    Map<String, String> queryParameters,
  ) async {
    final response = await WpApiService.get(_buildPostsUri(queryParameters));
    if (response.statusCode == 200) {
      return _decodeArticles(response.body);
    }
    return [];
  }

  Future<void> fetchCategories() async {
    try {
      final config = await CategoryConfig.load();

      final url = '${AppConfig.instance.apiBase}/wp-json/wp/v2/categories'
          '?per_page=${AppConfig.instance.categoriesPerPage}'
          '&_fields=id,name,slug,parent,count';

      final response = await WpApiService.get(Uri.parse(url));

      if (response.statusCode != 200) {
        _error = 'Failed to load categories';
        notifyListeners();
        return;
      }

      final allCategories = (json.decode(response.body) as List)
          .map((data) => Category.fromJson(data))
          .toList();

      final categoriesById = {
        for (final category in allCategories) category.id: category,
      };

      final rootCategories = <Category>[];

      for (final categoryId in config.includeIds) {
        final category = categoriesById[categoryId];

        if (category == null) {
          continue;
        }

        category.subcategories.clear();

        for (final dropdown in config.dropdowns) {
          if (dropdown.parentId != category.id) {
            continue;
          }

          for (final subcategoryId in dropdown.subcategories) {
            final subcategory = categoriesById[subcategoryId];

            if (subcategory != null) {
              category.subcategories.add(subcategory);
            }
          }
        }

        rootCategories.add(category);
      }

      _categories = rootCategories;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> fetchArticles({bool forceRefresh = false}) async {
    final generation = ++_fetchGeneration;
    _loading = true;
    notifyListeners();

    final perPage = AppConfig.instance.postsPerPage;
    final uri = _buildPostsUri({
      'page': '$_currentPage',
      'per_page': '$perPage',
      if (_selectedCategory != null) 'categories': '$_selectedCategory',
    });

    try {
      final response = await WpApiService.get(
        uri,
        forceRefresh: forceRefresh,
      );
      if (generation != _fetchGeneration) return;

      if (response.statusCode == 200) {
        final loadedArticles = await _decodeArticles(response.body);
        if (generation != _fetchGeneration) return;

        if (_currentPage == 1) {
          _articles = loadedArticles;
        } else {
          _articles.addAll(loadedArticles);
        }

        final totalPagesHeader = response.headers['x-wp-totalpages'] ??
            response.headers['X-WP-TotalPages'];
        if (totalPagesHeader != null) {
          _totalPages = int.tryParse(totalPagesHeader) ?? 1;
        } else if (loadedArticles.length == perPage) {
          if (_currentPage + 1 > _totalPages) {
            _totalPages = _currentPage + 1;
          }
        } else {
          _totalPages = _currentPage;
        }
        _error = null;
      } else {
        _error = 'Failed to load articles';
      }
    } catch (e) {
      if (generation != _fetchGeneration) return;
      _error = e.toString();
    } finally {
      if (generation == _fetchGeneration) {
        _loading = false;
        notifyListeners();
      }
    }
  }

  Future<List<Article>> searchArticles(String searchQuery) async {
    final query = searchQuery.trim();
    if (query.isEmpty) return [];

    try {
      return await _fetchPostsList({
        'search': query,
        'per_page': '${AppConfig.instance.searchResultsPerPage}',
      });
    } catch (_) {
      return [];
    }
  }

  Future<List<Article>> getArticlesByAuthor(
    String authorName, {
    int? authorId,
  }) async {
    var cleanName = authorName.trim();
    if (cleanName.toLowerCase().startsWith('by ')) {
      cleanName = cleanName.substring(3).trim();
    }
    if (cleanName.isEmpty) return [];

    final Map<int, Article> articlesById = {};

    // 1. Search posts matching the writer's name
    final searchResults = await searchArticles(cleanName);
    for (final article in searchResults) {
      articlesById[article.id] = article;
    }

    // 2. If a specific WordPress author ID is available and cleanName isn't the generic fallback,
    // also check posts by that WP author ID if their embedded author name matches.
    if (authorId != null &&
        authorId > 0 &&
        cleanName.toLowerCase() !=
            WpApiService.fallbackAuthorName.toLowerCase()) {
      try {
        final response = await WpApiService.get(
          _buildPostsUri({
            'author': '$authorId',
            'per_page': '${AppConfig.instance.searchResultsPerPage}',
            '_embed': 'author,wp:featuredmedia',
          }),
        );
        if (response.statusCode == 200) {
          final List<dynamic> data = json.decode(response.body);
          for (final item in data.whereType<Map<String, dynamic>>()) {
            final embedded = item['_embedded'];
            String wpUserName = '';
            if (embedded is Map &&
                embedded['author'] is List &&
                (embedded['author'] as List).isNotEmpty &&
                embedded['author'][0] is Map) {
              wpUserName =
                  embedded['author'][0]['name']?.toString().trim() ?? '';
            }
            if (wpUserName.toLowerCase() == cleanName.toLowerCase()) {
              final parsed = Article.fromJson(item);
              WpApiService.cacheAuthorName(parsed.link, cleanName);
              articlesById[parsed.id] = parsed;
            }
          }
        }
      } catch (_) {}
    }

    final combined = articlesById.values.toList();
    combined.sort((a, b) => b.date.compareTo(a.date));
    return combined;
  }

  /// Resolves an article from a Universal Link / App Link URL or path.
  /// Supports `/?p=123` post IDs as well as `/2026/10/post-slug/` permalinks.
  Future<Article?> fetchArticleBySlugOrUrl(String urlOrPath) async {
    final trimmed = urlOrPath.trim();
    if (trimmed.isEmpty) return null;

    final uri = Uri.tryParse(trimmed);
    if (uri == null) return null;

    // 1. Check query parameter ?p=<id>
    final postIdParam = uri.queryParameters['p'];
    if (postIdParam != null) {
      final postId = int.tryParse(postIdParam);
      if (postId != null && postId > 0) {
        return fetchArticleById(postId);
      }
    }

    // 2. Extract slug from the last non-empty path segment
    final segments =
        uri.pathSegments.where((segment) => segment.trim().isNotEmpty).toList();
    if (segments.isEmpty) return null;

    final lastSegment = segments.last.trim().toLowerCase();
    if (AppConfig.instance.nonArticleSlugs.contains(lastSegment)) {
      return null;
    }

    // Check if already in memory
    for (final existing in _articles) {
      final existingUri = Uri.tryParse(existing.link);
      if (existingUri != null) {
        final existingSegments =
            existingUri.pathSegments.where((s) => s.trim().isNotEmpty).toList();
        if (existingSegments.isNotEmpty &&
            existingSegments.last.toLowerCase() == lastSegment) {
          return existing;
        }
      }
    }

    try {
      final results = await _fetchPostsList({'slug': lastSegment});
      if (results.isNotEmpty) {
        return results.first;
      }
    } catch (_) {}

    return null;
  }

  void nextPage() {
    if (_loading) return;
    if (_currentPage < _totalPages) {
      _currentPage++;
      fetchArticles();
    }
  }

  void selectCategory(int? categoryId) {
    _selectedCategory = categoryId;
    _currentPage = 1;
    _totalPages = 1;
    _articles = [];
    _error = null;
    fetchArticles();
  }

  Future<void> refreshArticles() async {
    _currentPage = 1;
    _totalPages = 1;
    _articles = [];
    _error = null;
    await fetchArticles(forceRefresh: true);
  }

  Future<List<Article>> getArticlesByTag(
    int tagId, {
    int page = 1,
    int? perPage,
  }) async {
    final effectivePerPage = perPage ?? AppConfig.instance.searchResultsPerPage;
    try {
      return await _fetchPostsList({
        'tags': '$tagId',
        'page': '$page',
        'per_page': '$effectivePerPage',
      });
    } catch (_) {
      return [];
    }
  }

  void clearFilters() {
    _selectedCategory = null;
    _currentPage = 1;
    _totalPages = 1;
    _articles = [];
    _error = null;
    fetchArticles();
  }

  Future<Article?> fetchArticleById(int articleId) async {
    try {
      final response = await WpApiService.get(
        _buildPostsUri({}, postId: articleId),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Article.fromJson(data);
      }
    } catch (_) {}
    return null;
  }

  Future<List<Article>> getRelatedArticles(Article article) async {
    if (article.tags.isEmpty) return [];

    try {
      final config = AppConfig.instance;
      final results = await _fetchPostsList({
        'tags': article.tags.take(5).join(','),
        'per_page': '${config.relatedArticlesFetchPool}',
        'exclude': '${article.id}',
      });
      results.shuffle(Random());
      return results.take(config.relatedArticlesCount).toList();
    } catch (_) {
      return [];
    }
  }
}
