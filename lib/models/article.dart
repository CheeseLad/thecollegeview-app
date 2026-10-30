import '../utils/html_utils.dart';
import '../services/wp_api_service.dart';

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

  const Article({
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

  Article copyWith({
    String? embeddedFeaturedMediaUrl,
    String? embeddedAuthorName,
  }) {
    return Article(
      id: id,
      date: date,
      title: title,
      content: content,
      link: link,
      author: author,
      featuredMedia: featuredMedia,
      tags: tags,
      embeddedFeaturedMediaUrl:
          embeddedFeaturedMediaUrl ?? this.embeddedFeaturedMediaUrl,
      embeddedAuthorName: embeddedAuthorName ?? this.embeddedAuthorName,
    );
  }

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
    final embedded = json['_embedded'];
    if (embedded is Map) {
      final mediaList = embedded['wp:featuredmedia'];
      if (mediaList is List && mediaList.isNotEmpty && mediaList[0] is Map) {
        embeddedMedia = mediaList[0]['source_url']?.toString();
      }
    }

    final featuredMedia =
        int.tryParse(json['featured_media']?.toString() ?? '0') ?? 0;
    final link = json['link']?.toString() ?? '';

    if (embeddedMedia != null &&
        embeddedMedia.isNotEmpty &&
        featuredMedia > 0) {
      WpApiService.cacheFeaturedMediaUrl(featuredMedia, embeddedMedia);
    }

    return Article(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      date: json['date']?.toString() ?? '',
      title: HtmlUtils.decodeHtmlEntities(titleRendered),
      content: HtmlUtils.decodeHtmlEntitiesPreserveTags(contentRendered),
      link: link,
      author: int.tryParse(json['author']?.toString() ?? '0') ?? 0,
      featuredMedia: featuredMedia,
      tags: tags,
      embeddedFeaturedMediaUrl: embeddedMedia,
    );
  }
}
