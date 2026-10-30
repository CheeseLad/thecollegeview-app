import 'package:intl/intl.dart';
import '../utils/html_utils.dart';
import '../services/wp_api_service.dart';

class Article {
  static final DateFormat _dateFormat = DateFormat('MMMM d, y');
  static final Map<String, String> _formattedDateCache = {};

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
  final String? _precomputedFormattedDate;

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
    String? formattedDate,
  }) : _precomputedFormattedDate = formattedDate;

  static String _formatRawDate(String rawDate) {
    if (rawDate.isEmpty) return '';
    final parsed = DateTime.tryParse(rawDate);
    return parsed != null ? '⏰ ${_dateFormat.format(parsed)}' : '';
  }

  String get formattedDate {
    final precomputed = _precomputedFormattedDate;
    if (precomputed != null) return precomputed;
    if (date.isEmpty) return '';
    return _formattedDateCache.putIfAbsent(date, () => _formatRawDate(date));
  }

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
      formattedDate: _precomputedFormattedDate,
    );
  }

  /// Extracts a sized image URL (`large` or `medium_large`) from a WordPress
  /// media JSON object if available, falling back to the full `source_url`.
  static String? extractPreferredMediaUrl(Map mediaJson) {
    final details = mediaJson['media_details'];
    if (details is Map) {
      final sizes = details['sizes'];
      if (sizes is Map) {
        for (final sizeKey in const ['large', 'medium_large', 'medium']) {
          final sizeObj = sizes[sizeKey];
          if (sizeObj is Map) {
            final sizedUrl = sizeObj['source_url']?.toString();
            if (sizedUrl != null && sizedUrl.isNotEmpty) {
              return sizedUrl;
            }
          }
        }
      }
    }
    return mediaJson['source_url']?.toString();
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
        embeddedMedia = extractPreferredMediaUrl(mediaList[0] as Map);
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

    final dateStr = json['date']?.toString() ?? '';

    return Article(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      date: dateStr,
      title: HtmlUtils.decodeHtmlEntities(titleRendered),
      content: HtmlUtils.decodeHtmlEntitiesPreserveTags(contentRendered),
      link: link,
      author: int.tryParse(json['author']?.toString() ?? '0') ?? 0,
      featuredMedia: featuredMedia,
      tags: tags,
      embeddedFeaturedMediaUrl: embeddedMedia,
      formattedDate: _formatRawDate(dateStr),
    );
  }
}
