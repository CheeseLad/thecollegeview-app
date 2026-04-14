import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/saved_article.dart';
import '../models/article.dart';

class SavedArticlesProvider extends ChangeNotifier {
  static const String _boxName = 'savedArticles';
  late Box<Map> _box;
  List<SavedArticle> _savedArticles = [];

  List<SavedArticle> get savedArticles => _savedArticles;

  Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox<Map>(_boxName);
    _loadSavedArticles();
  }

  void _loadSavedArticles() {
    _savedArticles = _box.values.map((map) => SavedArticle.fromMap(map)).toList();
    _savedArticles.sort((a, b) => b.savedAt.compareTo(a.savedAt));
    notifyListeners();
  }

  bool isArticleSaved(int articleId) {
    return _savedArticles.any((article) => article.id == articleId);
  }

  Future<void> saveArticle(Article article, String categoryName) async {
    if (isArticleSaved(article.id)) {
      return; // Article already saved
    }

    final savedArticle = SavedArticle.fromArticle(article, categoryName);
    await _box.add(savedArticle.toMap());
    _loadSavedArticles();
  }

  Future<void> removeArticle(int articleId) async {
    final articleToRemove = _savedArticles.firstWhere(
      (article) => article.id == articleId,
      orElse: () => throw Exception('Article not found'),
    );

    final index = _savedArticles.indexOf(articleToRemove);
    await _box.deleteAt(index);
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
    _box.close();
    super.dispose();
  }
}
