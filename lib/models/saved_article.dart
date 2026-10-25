import 'package:hive/hive.dart';
import 'article.dart';

class SavedArticle extends HiveObject {
  final int id;
  final String date;
  final String title;
  final String content;
  final String link;
  final int author;
  final int featuredMedia;
  final String categoryName;
  final DateTime savedAt;
  final List<int> tags;
  final String featuredMediaUrl;
  final String authorName;
  final List<String> tagNames;

  SavedArticle({
    required this.id,
    required this.date,
    required this.title,
    required this.content,
    required this.link,
    required this.author,
    required this.featuredMedia,
    required this.categoryName,
    required this.savedAt,
    required this.tags,
    this.featuredMediaUrl = '',
    this.authorName = '',
    this.tagNames = const [],
  });

  factory SavedArticle.fromArticle(
    Article article,
    String categoryName, {
    String featuredMediaUrl = '',
    String authorName = '',
    List<String> tagNames = const [],
  }) {
    return SavedArticle(
      id: article.id,
      date: article.date,
      title: article.title,
      content: article.content,
      link: article.link,
      author: article.author,
      featuredMedia: article.featuredMedia,
      categoryName: categoryName,
      savedAt: DateTime.now(),
      tags: article.tags,
      featuredMediaUrl: featuredMediaUrl,
      authorName: authorName,
      tagNames: tagNames,
    );
  }

  Article toArticle() {
    return Article(
      id: id,
      date: date,
      title: title,
      content: content,
      link: link,
      author: author,
      featuredMedia: featuredMedia,
      tags: tags,
      embeddedFeaturedMediaUrl: featuredMediaUrl,
      embeddedAuthorName: authorName,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'title': title,
      'content': content,
      'link': link,
      'author': author,
      'featuredMedia': featuredMedia,
      'categoryName': categoryName,
      'savedAt': savedAt.toIso8601String(),
      'tags': tags,
      'featuredMediaUrl': featuredMediaUrl,
      'authorName': authorName,
      'tagNames': tagNames,
    };
  }

  factory SavedArticle.fromMap(Map map) {
    return SavedArticle(
      id: int.tryParse(map['id']?.toString() ?? '0') ?? 0,
      date: map['date']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      content: map['content']?.toString() ?? '',
      link: map['link']?.toString() ?? '',
      author: int.tryParse(map['author']?.toString() ?? '0') ?? 0,
      featuredMedia: int.tryParse(map['featuredMedia']?.toString() ?? '0') ?? 0,
      categoryName: map['categoryName']?.toString() ?? 'All Articles',
      savedAt:
          DateTime.tryParse(map['savedAt']?.toString() ?? '') ?? DateTime.now(),
      tags: (map['tags'] as List? ?? [])
          .map((t) => int.tryParse(t.toString()) ?? 0)
          .where((t) => t > 0)
          .toList(),
      featuredMediaUrl: map['featuredMediaUrl']?.toString() ?? '',
      authorName: map['authorName']?.toString() ?? '',
      tagNames:
          (map['tagNames'] as List? ?? []).map((t) => t.toString()).toList(),
    );
  }
}
