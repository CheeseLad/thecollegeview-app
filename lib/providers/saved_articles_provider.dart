import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/saved_article.dart';
import '../models/article.dart';
import '../services/wp_api_service.dart';

class SavedArticlesProvider extends ChangeNotifier {
  static const String _boxName = 'savedArticles';
  late Box<Map> _box;
  List<SavedArticle> _savedArticles = [];

  List<SavedArticle> get savedArticles => _savedArticles;

  Future<void> init() async {
    try {
      _box = await Hive.openBox<Map>(_boxName);
    } catch (_) {
      // In case of box corruption, attempt recovery
      await Hive.deleteBoxFromDisk(_boxName);
      _box = await Hive.openBox<Map>(_boxName);
    }
    _loadSavedArticles();
  }

  void _loadSavedArticles() {
    final loaded = <SavedArticle>[];
    for (final key in _box.keys) {
      final value = _box.get(key);
      if (value != null) {
        try {
          loaded.add(SavedArticle.fromMap(value));
        } catch (_) {
          // Ignore malformed entries
        }
      }
    }
    loaded.sort((a, b) => b.savedAt.compareTo(a.savedAt));
    _savedArticles = loaded;
    notifyListeners();
  }

  bool isArticleSaved(int articleId) {
    if (_box.isOpen && _box.containsKey(articleId.toString())) {
      return true;
    }
    return _savedArticles.any((article) => article.id == articleId);
  }

  Future<void> saveArticle(Article article, String categoryName) async {
    if (isArticleSaved(article.id)) {
      return;
    }

    final featuredMediaUrl =
        await WpApiService.fetchFeaturedMediaUrl(article.featuredMedia);
    final authorName =
        await WpApiService.fetchAuthorName(article.link, article.author);
    final tagNames = await WpApiService.fetchTagNames(article.tags);

    final savedArticle = SavedArticle.fromArticle(
      article,
      categoryName,
      featuredMediaUrl: featuredMediaUrl,
      authorName: authorName,
      tagNames: tagNames,
    );
    await _box.put(article.id.toString(), savedArticle.toMap());
    _loadSavedArticles();
  }

  Future<void> removeArticle(int articleId) async {
    final key = articleId.toString();
    if (_box.containsKey(key)) {
      await _box.delete(key);
    } else {
      // Legacy fallback: find key whose map has matching id
      dynamic matchingKey;
      for (final k in _box.keys) {
        final val = _box.get(k);
        if (val != null && val['id'] == articleId) {
          matchingKey = k;
          break;
        }
      }
      if (matchingKey != null) {
        await _box.delete(matchingKey);
      }
    }
    _loadSavedArticles();
  }

  Future<void> toggleSaveArticle(Article article, String categoryName) async {
    if (isArticleSaved(article.id)) {
      await removeArticle(article.id);
    } else {
      await saveArticle(article, categoryName);
    }
  }

  Future<void> refreshSavedArticles() async {
    _loadSavedArticles();
  }

  @override
  void dispose() {
    if (_box.isOpen) {
      _box.close();
    }
    super.dispose();
  }
}
