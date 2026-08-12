import 'dart:convert';
import 'package:flutter/material.dart';
import '../config/category_config.dart';
import '../models/article.dart';
import '../models/category.dart';
import '../models/tag.dart';
import '../services/wp_api_service.dart';

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
      final includeIds = config.includeIds;
      final idsParam = includeIds.isEmpty ? '' : '?include=${includeIds.join(',')}';
      final url = 'https://thecollegeview.ie/wp-json/wp/v2/categories$idsParam';
      final response = await WpApiService.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final allCategories = (json.decode(response.body) as List)
            .map((data) => Category.fromJson(data))
            .toList();
        final categoriesById = {
          for (final category in allCategories) category.id: category,
        };

        final rootCategories = <Category>[];
        final dropdownParentIds = config.dropdowns.map((item) => item.parentId).toSet();
        final childCategoryIds = config.dropdowns
            .expand((item) => item.subcategories)
            .toSet();

        final orderedIds = config.includeIds;
        final orderedById = <int, Category>{};

        for (final category in allCategories) {
          if (!orderedIds.contains(category.id)) {
            continue;
          }

          final dropdown = config.dropdowns.firstWhere(
            (item) => item.parentId == category.id,
            orElse: () => const CategoryDropdown(parentId: 0, subcategories: []),
          );

          category.subcategories.clear();

          final orderedSubcategories = <Category>[];
          for (final subcategoryId in dropdown.subcategories) {
            final subcategory = categoriesById[subcategoryId];
            if (subcategory != null) {
              orderedSubcategories.add(subcategory);
            }
          }

          category.subcategories.addAll(orderedSubcategories);

          final isConfiguredParent = dropdownParentIds.contains(category.id);
          final isConfiguredChild = childCategoryIds.contains(category.id);

          if (isConfiguredParent || (!isConfiguredChild && !dropdownParentIds.contains(category.id))) {
            orderedById[category.id] = category;
          }
        }

        for (final id in orderedIds) {
          final category = orderedById[id];
          if (category != null) {
            rootCategories.add(category);
          }
        }

        _categories = rootCategories;
        notifyListeners();
      } else {
        _error = 'Failed to load categories';
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> fetchStickyArticles() async {
    const url =
        'https://thecollegeview.ie/wp-json/wp/v2/posts?sticky=true&_fields=id,date,title,content,link,author,featured_media,tags';
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

  Future<void> fetchArticles() async {
    _loading = true;
    notifyListeners();

    final categoryFilter =
        _selectedCategory != null ? '&categories=$_selectedCategory' : '';
    final tagFilter = _selectedTag != null ? '&tags=$_selectedTag' : '';
    final url =
        'https://thecollegeview.ie/wp-json/wp/v2/posts/?page=$_currentPage&per_page=10$categoryFilter$tagFilter&_fields=id,date,title,content,link,author,featured_media,tags';
    try {
      final response = await WpApiService.get(Uri.parse(url));
      if (response.statusCode == 200) {
        List<Article> loadedArticles = (json.decode(response.body) as List)
            .map((data) => Article.fromJson(data))
            .toList();
        _articles = loadedArticles;
        _totalPages = int.parse(response.headers['x-wp-totalpages']!);
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

  Future<void> searchArticles(String searchQuery) async {
    final url =
        'https://thecollegeview.ie/wp-json/wp/v2/posts?search=$searchQuery';
    try {
      final response = await WpApiService.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _articles = data.map((json) => Article.fromJson(json)).toList();
        notifyListeners();
      } else {
        throw Exception('Failed to load articles');
      }
    } catch (error) {
      print('Error searching articles: $error');
    }
  }

  void nextPage() {
    if (_currentPage < _totalPages) {
      _currentPage++;
      fetchArticles();
    }
  }

  void previousPage() {
    if (_currentPage > 1) {
      _currentPage--;
      fetchArticles();
    }
  }

  void selectCategory(int? categoryId) {
    _selectedCategory = categoryId;
    _currentPage = 1;
    fetchArticles();
  }

  Future<void> refreshArticles() async {
    _currentPage = 1;
    await fetchArticles();
  }

  Future<void> fetchTags() async {
    const url = 'https://thecollegeview.ie/wp-json/wp/v2/tags?per_page=100';
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

  Future<void> fetchArticlesByTag(int tagId) async {
    _selectedTag = tagId;
    _selectedCategory = null;
    _currentPage = 1;
    await fetchArticles();
  }

  void selectTag(int? tagId) {
    _selectedTag = tagId;
    _selectedCategory = null;
    _currentPage = 1;
    fetchArticles();
  }

  void clearFilters() {
    _selectedCategory = null;
    _selectedTag = null;
    _currentPage = 1;
    fetchArticles();
  }

  Future<Article?> fetchArticleById(int articleId) async {
    try {
      final response = await WpApiService.get(
        Uri.parse('https://thecollegeview.ie/wp-json/wp/v2/posts/$articleId?_fields=id,date,title,content,link,author,featured_media,tags'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Article.fromJson(data);
      } else {
        return null;
      }
    } catch (e) {
      print('Error fetching article by ID: $e');
      return null;
    }
  }
}
