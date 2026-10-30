import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import '../config/category_config.dart';
import '../models/article.dart';
import '../models/category.dart';
import '../models/tag.dart';
import '../services/wp_api_service.dart';
import '../config/app_urls.dart';

class ArticleProvider with ChangeNotifier {
  List<Article> _articles = [];
  List<Category> _categories = [];
  List<Tag> _tags = [];
  bool _loading = false;
  String? _error;
  int _currentPage = 1;
  int _totalPages = 1;
  int? _selectedCategory;
  int? _selectedTag;
  List<int> _pageSizes = [];

  List<Article> get articles => _articles;
  List<Category> get categories => _categories;
  List<Tag> get tags => _tags;
  bool get loading => _loading;
  String? get error => _error;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int? get selectedCategory => _selectedCategory;
  int? get selectedTag => _selectedTag;

  ArticleProvider() {
    fetchCategories();
    fetchTags();
    fetchArticles();
  }

  Future<void> fetchCategories() async {
    try {
      final config = await CategoryConfig.load();

      final url = '${AppUrls.apiBase}/wp-json/wp/v2/categories'
          '?per_page=100'
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

  Future<void> fetchStickyArticles() async {
    final url =
        '${AppUrls.apiBase}/wp-json/wp/v2/posts?sticky=true&_fields=id,date,title,content,link,author,featured_media,tags';
    try {
      final response = await WpApiService.get(Uri.parse(url));
      if (response.statusCode == 200) {
        List<Article> loadedArticles = (json.decode(response.body) as List)
            .map((data) => Article.fromJson(data))
            .toList();
        _articles = loadedArticles;
        _error = null;
      } else {
        _error = 'Failed to load sticky articles';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      notifyListeners();
    }
  }

  Future<void> fetchArticles({bool forceRefresh = false}) async {
    _loading = true;
    notifyListeners();

    final categoryFilter =
        _selectedCategory != null ? '&categories=$_selectedCategory' : '';
    final tagFilter = _selectedTag != null ? '&tags=$_selectedTag' : '';
    final url =
        '${AppUrls.apiBase}/wp-json/wp/v2/posts/?page=$_currentPage&per_page=10$categoryFilter$tagFilter&_fields=id,date,title,content,link,author,featured_media,tags,_links,_embedded&_embed=author,wp:featuredmedia';
    try {
      final response = await WpApiService.get(
        Uri.parse(url),
        forceRefresh: forceRefresh,
      );
      if (response.statusCode == 200) {
        List<Article> loadedArticles = (json.decode(response.body) as List)
            .map((data) => Article.fromJson(data))
            .toList();

        if (_currentPage == 1) {
          _articles = loadedArticles;
          _pageSizes = [loadedArticles.length];
        } else {
          _articles.addAll(loadedArticles);
          _pageSizes.add(loadedArticles.length);
        }

        final totalPagesHeader = response.headers['x-wp-totalpages'] ??
            response.headers['X-WP-TotalPages'];
        if (totalPagesHeader != null) {
          _totalPages = int.tryParse(totalPagesHeader) ?? 1;
        } else if (loadedArticles.length == 10) {
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
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<List<Article>> searchArticles(String searchQuery) async {
    final query = searchQuery.trim();
    if (query.isEmpty) return [];

    final encodedQuery = Uri.encodeQueryComponent(query);
    final url =
        '${AppUrls.apiBase}/wp-json/wp/v2/posts?search=$encodedQuery&per_page=20&_fields=id,date,title,content,link,author,featured_media,tags,_links,_embedded&_embed=author,wp:featuredmedia';
    try {
      final response = await WpApiService.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Article.fromJson(json)).toList();
      }
    } catch (_) {}
    return [];
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
        final url =
            '${AppUrls.apiBase}/wp-json/wp/v2/posts?author=$authorId&per_page=20&_fields=id,date,title,content,link,author,featured_media,tags,_links,_embedded&_embed=author,wp:featuredmedia';
        final response = await WpApiService.get(Uri.parse(url));
        if (response.statusCode == 200) {
          final List<dynamic> data = json.decode(response.body);
          for (final item in data) {
            if (item is Map<String, dynamic>) {
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
    const nonArticleSlugs = {
      'about',
      'contact',
      'category',
      'tag',
      'author',
      'search',
      'wp-admin',
      'wp-login.php',
      'feed',
    };
    if (nonArticleSlugs.contains(lastSegment)) {
      return null;
    }

    // Check if already in memory
    for (final existing in _articles) {
      final existingUri = Uri.tryParse(existing.link);
      if (existingUri != null) {
        final existingSegments = existingUri.pathSegments
            .where((s) => s.trim().isNotEmpty)
            .toList();
        if (existingSegments.isNotEmpty &&
            existingSegments.last.toLowerCase() == lastSegment) {
          return existing;
        }
      }
    }

    try {
      final encodedSlug = Uri.encodeQueryComponent(lastSegment);
      final response = await WpApiService.get(
        Uri.parse(
          '${AppUrls.apiBase}/wp-json/wp/v2/posts?slug=$encodedSlug&_fields=id,date,title,content,link,author,featured_media,tags,_links,_embedded&_embed=author,wp:featuredmedia',
        ),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List && data.isNotEmpty && data[0] is Map<String, dynamic>) {
          return Article.fromJson(data[0] as Map<String, dynamic>);
        }
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

  void previousPage() {
    if (_loading) return;
    if (_currentPage > 1 && _pageSizes.length >= _currentPage) {
      _currentPage--;
      _articles =
          _articles.sublist(0, _articles.length - _pageSizes[_currentPage]);
      _pageSizes = _pageSizes.sublist(0, _currentPage);
      notifyListeners();
    }
  }

  void selectCategory(int? categoryId) {
    _selectedCategory = categoryId;
    _currentPage = 1;
    _pageSizes = [];
    fetchArticles();
  }

  Future<void> refreshArticles() async {
    _currentPage = 1;
    _pageSizes = [];
    await fetchArticles(forceRefresh: true);
  }

  Future<void> fetchTags() async {
    final url = '${AppUrls.apiBase}/wp-json/wp/v2/tags?per_page=100';
    try {
      final response = await WpApiService.get(Uri.parse(url));
      if (response.statusCode == 200) {
        List<Tag> loadedTags = (json.decode(response.body) as List)
            .map((data) => Tag.fromJson(data))
            .toList();
        _tags = loadedTags;
        notifyListeners();
      } else {
        _error = 'Failed to load tags';
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<List<Article>> getArticlesByTag(int tagId,
      {int page = 1, int perPage = 20}) async {
    final url =
        '${AppUrls.apiBase}/wp-json/wp/v2/posts/?tags=$tagId&page=$page&per_page=$perPage&_fields=id,date,title,content,link,author,featured_media,tags,_links,_embedded&_embed=author,wp:featuredmedia';
    try {
      final response = await WpApiService.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Article.fromJson(json)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<void> fetchArticlesByTag(int tagId) async {
    _selectedTag = tagId;
    _selectedCategory = null;
    _currentPage = 1;
    _pageSizes = [];
    await fetchArticles();
  }

  void selectTag(int? tagId) {
    _selectedTag = tagId;
    _selectedCategory = null;
    _currentPage = 1;
    _pageSizes = [];
    fetchArticles();
  }

  void clearFilters() {
    _selectedCategory = null;
    _selectedTag = null;
    _currentPage = 1;
    _pageSizes = [];
    fetchArticles();
  }

  Future<Article?> fetchArticleById(int articleId) async {
    try {
      final response = await WpApiService.get(
        Uri.parse(
            '${AppUrls.apiBase}/wp-json/wp/v2/posts/$articleId?_fields=id,date,title,content,link,author,featured_media,tags,_links,_embedded&_embed=author,wp:featuredmedia'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Article.fromJson(data);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  Future<List<Article>> getRelatedArticles(Article article) async {
    if (article.tags.isEmpty) return [];

    final tagIds = article.tags.take(5).join(',');
    final url =
        '${AppUrls.apiBase}/wp-json/wp/v2/posts?tags=$tagIds&per_page=10&exclude=${article.id}&_fields=id,date,title,content,link,author,featured_media,tags,_links,_embedded&_embed=author,wp:featuredmedia';
    try {
      final response = await WpApiService.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final results = (json.decode(response.body) as List)
            .map((data) => Article.fromJson(data))
            .toList();
        results.shuffle(Random());
        return results.take(3).toList();
      }
    } catch (e) {
      // ignore
    }
    return [];
  }
}
