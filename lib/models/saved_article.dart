import 'article.dart';

class SavedArticle {
  final Article article;
  final String categoryName;
  final DateTime savedAt;
  final List<String> tagNames;

  const SavedArticle({
    required this.article,
    required this.categoryName,
    required this.savedAt,
    this.tagNames = const [],
  });

  int get id => article.id;

  factory SavedArticle.fromArticle(
    Article article,
    String categoryName, {
    String featuredMediaUrl = '',
    String authorName = '',
    List<String> tagNames = const [],
  }) {
    return SavedArticle(
      article: article.copyWith(
        embeddedFeaturedMediaUrl:
            featuredMediaUrl.isNotEmpty ? featuredMediaUrl : null,
        embeddedAuthorName: authorName.isNotEmpty ? authorName : null,
      ),
      categoryName: categoryName,
      savedAt: DateTime.now(),
      tagNames: tagNames,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': article.id,
      'date': article.date,
      'title': article.title,
      'content': article.content,
      'link': article.link,
      'author': article.author,
      'featuredMedia': article.featuredMedia,
      'categoryName': categoryName,
      'savedAt': savedAt.toIso8601String(),
      'tags': article.tags,
      'featuredMediaUrl': article.embeddedFeaturedMediaUrl ?? '',
      'authorName': article.embeddedAuthorName ?? '',
      'tagNames': tagNames,
    };
  }

  factory SavedArticle.fromMap(Map map) {
    final featuredMediaUrl = map['featuredMediaUrl']?.toString() ?? '';
    final authorName = map['authorName']?.toString() ?? '';

    return SavedArticle(
      article: Article(
        id: int.tryParse(map['id']?.toString() ?? '0') ?? 0,
        date: map['date']?.toString() ?? '',
        title: map['title']?.toString() ?? '',
        content: map['content']?.toString() ?? '',
        link: map['link']?.toString() ?? '',
        author: int.tryParse(map['author']?.toString() ?? '0') ?? 0,
        featuredMedia:
            int.tryParse(map['featuredMedia']?.toString() ?? '0') ?? 0,
        tags: (map['tags'] as List? ?? [])
            .map((t) => int.tryParse(t.toString()) ?? 0)
            .where((t) => t > 0)
            .toList(),
        embeddedFeaturedMediaUrl:
            featuredMediaUrl.isNotEmpty ? featuredMediaUrl : null,
        embeddedAuthorName: authorName.isNotEmpty ? authorName : null,
      ),
      categoryName: map['categoryName']?.toString() ?? 'All Articles',
      savedAt:
          DateTime.tryParse(map['savedAt']?.toString() ?? '') ?? DateTime.now(),
      tagNames:
          (map['tagNames'] as List? ?? []).map((t) => t.toString()).toList(),
    );
  }
}
