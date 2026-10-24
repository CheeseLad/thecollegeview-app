import '../utils/html_utils.dart';

class Article {
  final int id;
  final String date;
  final String title;
  final String content;
  final String link;
  final int author;
  final int featuredMedia;
  final List<int> tags;
  final String? embeddedFeaturedMediaUrl;
  final String? embeddedAuthorName;

  Article({
    required this.id,
    required this.date,
    required this.title,
    required this.content,
    required this.link,
    required this.author,
    required this.featuredMedia,
    required this.tags,
    this.embeddedFeaturedMediaUrl,
    this.embeddedAuthorName,
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    final rawTags = json['tags'];
    final List<int> tags = rawTags is List
        ? rawTags
            .map((t) => int.tryParse(t.toString()) ?? 0)
            .where((t) => t > 0)
            .toList()
        : [];

    final titleRendered = json['title'] is Map
        ? (json['title']['rendered']?.toString() ?? '')
        : (json['title']?.toString() ?? '');

    final contentRendered = json['content'] is Map
        ? (json['content']['rendered']?.toString() ?? '')
        : (json['content']?.toString() ?? '');

    // Extract embedded data if present (e.g. from ?_embed)
    String? embeddedMedia;
    String? embeddedAuthor;
    final embedded = json['_embedded'];
    if (embedded is Map) {
      final mediaList = embedded['wp:featuredmedia'];
      if (mediaList is List && mediaList.isNotEmpty && mediaList[0] is Map) {
        embeddedMedia = mediaList[0]['source_url']?.toString();
      }
      final authorList = embedded['author'];
      if (authorList is List && authorList.isNotEmpty && authorList[0] is Map) {
        final rawAuthor = authorList[0]['name']?.toString();
        if (rawAuthor != null && rawAuthor.isNotEmpty) {
          embeddedAuthor = HtmlUtils.decodeHtmlEntities(rawAuthor);
        }
      }
    }

    return Article(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      date: json['date']?.toString() ?? '',
      title: HtmlUtils.decodeHtmlEntities(titleRendered),
      content: HtmlUtils.decodeHtmlEntitiesPreserveTags(contentRendered),
      link: json['link']?.toString() ?? '',
      author: int.tryParse(json['author']?.toString() ?? '0') ?? 0,
      featuredMedia:
          int.tryParse(json['featured_media']?.toString() ?? '0') ?? 0,
      tags: tags,
      embeddedFeaturedMediaUrl: embeddedMedia,
      embeddedAuthorName: embeddedAuthor,
    );
  }
}
