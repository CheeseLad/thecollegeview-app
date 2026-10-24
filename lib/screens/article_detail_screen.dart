import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/article.dart';
import '../models/tag.dart';
import '../providers/article_provider.dart';
import '../providers/saved_articles_provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/wp_api_service.dart';
import '../widgets/network_image_with_fallback.dart';
import 'tag_articles_screen.dart';

class ArticleDetailScreen extends StatefulWidget {
  final Article article;
  final String categoryName;
  final String? featuredMediaUrl;
  final String? authorName;
  final List<String>? tagNames;

  const ArticleDetailScreen({
    super.key,
    required this.article,
    required this.categoryName,
    this.featuredMediaUrl,
    this.authorName,
    this.tagNames,
  });

  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> {
  late Future<String> _authorNameFuture;
  late Future<String> _featuredMediaUrlFuture;
  late Future<List<String>> _tagNamesFuture;
  final GlobalKey _shareButtonKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _authorNameFuture = _resolveAuthorName();
    _featuredMediaUrlFuture = _resolveFeaturedMediaUrl();
    _tagNamesFuture = _resolveTagNames();
  }

  Future<String> _resolveAuthorName() async {
    final cached = widget.authorName ?? widget.article.embeddedAuthorName;
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }
    return await WpApiService.fetchAuthorName(
        widget.article.link, widget.article.author);
  }

  Future<String> _resolveFeaturedMediaUrl() async {
    final cached =
        widget.featuredMediaUrl ?? widget.article.embeddedFeaturedMediaUrl;
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }
    if (widget.article.featuredMedia <= 0) return '';
    return await WpApiService.fetchFeaturedMediaUrl(
        widget.article.featuredMedia);
  }

  Future<List<String>> _resolveTagNames() async {
    final cached = widget.tagNames;
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }
    return await WpApiService.fetchTagNames(widget.article.tags);
  }

  Future<void> _shareArticle() async {
    final link = widget.article.link.trim();
    if (link.isEmpty) return;

    final uri = Uri.tryParse(link);
    if (uri == null) return;

    Rect? sharePositionOrigin;
    final renderBox =
        _shareButtonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final size = renderBox.size;
      final position = renderBox.localToGlobal(Offset.zero);
      sharePositionOrigin = Rect.fromLTWH(
        position.dx,
        position.dy,
        size.width,
        size.height,
      );
    }

    try {
      await Share.shareUri(
        uri,
        sharePositionOrigin: sharePositionOrigin,
      );
    } catch (_) {
      try {
        await Share.share(
          link,
          sharePositionOrigin: sharePositionOrigin,
        );
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final parsedDate = DateTime.tryParse(widget.article.date);
    final String formattedDate = parsedDate != null
        ? '⏰ ${DateFormat('MMMM d, y').format(parsedDate)}'
        : '';
    final savedArticlesProvider = Provider.of<SavedArticlesProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.article.title),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4.0),
            child: IconButton(
              icon: Icon(
                savedArticlesProvider.isArticleSaved(widget.article.id)
                    ? Icons.bookmark
                    : Icons.bookmark_border,
                color: savedArticlesProvider.isArticleSaved(widget.article.id)
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              onPressed: () {
                savedArticlesProvider.toggleSaveArticle(
                    widget.article, widget.categoryName);
              },
            ),
          ),
        ],
      ),
      body: Container(
        color: Theme.of(context).colorScheme.surface,
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: SingleChildScrollView(
            child: SelectionArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.article.title,
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (formattedDate.isNotEmpty)
                        Text(formattedDate,
                            style: TextStyle(
                              fontSize: 16,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            )),
                      FutureBuilder<String>(
                        future: _authorNameFuture,
                        builder: (context, snapshot) {
                          final author = snapshot.data ??
                              widget.authorName ??
                              widget.article.embeddedAuthorName ??
                              '';
                          if (author.isEmpty) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              );
                            }
                            return const SizedBox.shrink();
                          }
                          return Text(
                            '👤 $author',
                            style: TextStyle(
                              fontSize: 16,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          );
                        },
                      ),
                      Text(
                        '📂 ${widget.categoryName}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  // Show tag on a new line if viewing tagged articles
                  if (widget.categoryName.startsWith('Tag: ')) ...[
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Text('🏷️ '),
                        Text(
                          () {
                            final tagName = widget.categoryName.substring(5);
                            return tagName.isEmpty
                                ? tagName
                                : tagName[0].toUpperCase() +
                                    tagName.substring(1);
                          }(),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 10),
                  // Display featured media if available
                  if (widget.article.featuredMedia > 0 ||
                      (widget.article.embeddedFeaturedMediaUrl != null &&
                          widget.article.embeddedFeaturedMediaUrl!.isNotEmpty))
                    FutureBuilder<String>(
                      future: _featuredMediaUrlFuture,
                      builder: (context, snapshot) {
                        final mediaUrl = snapshot.data ??
                            widget.featuredMediaUrl ??
                            widget.article.embeddedFeaturedMediaUrl ??
                            '';
                        if (mediaUrl.isNotEmpty) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 20),
                            child: NetworkImageWithFallback(
                              imageUrl: mediaUrl,
                              fallbackAssetPath: 'assets/logo.png',
                              width: double.infinity,
                              height: 220,
                              fit: BoxFit.cover,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          );
                        } else if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Container(
                            width: double.infinity,
                            height: 200,
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  HtmlWidget(
                    widget.article.content,
                    renderMode: RenderMode.column,
                    textStyle: const TextStyle(fontSize: 16),
                    onTapUrl: (url) async {
                      final uri = Uri.tryParse(url);
                      if (uri != null && await canLaunchUrl(uri)) {
                        await launchUrl(uri,
                            mode: LaunchMode.externalApplication);
                        return true;
                      }
                      return false;
                    },
                    customStylesBuilder: (element) {
                      if (element.localName == 'img') {
                        return {
                          'border-radius': '10px',
                        };
                      }
                      return null;
                    },
                    customWidgetBuilder: (element) {
                      if (element.localName == 'img') {
                        final src = element.attributes['src'];
                        if (src != null && src.isNotEmpty) {
                          return NetworkImageWithFallback(
                            imageUrl: src,
                            fallbackAssetPath: 'assets/logo.png',
                            borderRadius: BorderRadius.circular(10),
                          );
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  // Display tags if available
                  if (widget.article.tags.isNotEmpty) ...[
                    FutureBuilder<List<String>>(
                      future: _tagNamesFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const SizedBox.shrink();
                        } else if (snapshot.hasData &&
                            snapshot.data!.isNotEmpty) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                //const Text(
                                //  'Tags:',
                                //  style: TextStyle(
                                //    fontSize: 16,
                                //    fontWeight: FontWeight.bold,
                                //    color: Colors.grey,
                                //  ),
                                //),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8.0,
                                  runSpacing: 4.0,
                                  children: snapshot.data!
                                      .asMap()
                                      .entries
                                      .map((entry) {
                                    final index = entry.key;
                                    final tagName = entry.value;
                                    final tagId = widget.article.tags[index];

                                    return GestureDetector(
                                      onTap: () async {
                                        // Create a Tag object for navigation
                                        final tag = Tag(
                                          id: tagId,
                                          name: tagName,
                                          slug: tagName
                                              .toLowerCase()
                                              .replaceAll(' ', '-'),
                                          description: '',
                                          count: 0,
                                        );

                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                TagArticlesScreen(tag: tag),
                                          ),
                                        );
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primaryContainer,
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          border: Border.all(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              tagName,
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onPrimaryContainer,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Icon(
                                              Icons.arrow_forward_ios,
                                              size: 12,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onPrimaryContainer,
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          );
                        } else {
                          return const SizedBox.shrink();
                        }
                      },
                    ),
                  ] else ...[
                    const SizedBox.shrink(),
                  ],
                  InkWell(
                    key: _shareButtonKey,
                    borderRadius: BorderRadius.circular(8),
                    onTap: _shareArticle,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: Theme.of(context).colorScheme.outline,
                            width: 1.0),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.share),
                          SizedBox(width: 8.0),
                          Text(
                            "Share",
                            style: TextStyle(
                              fontSize: 18.0,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _RelatedArticlesSection(
                    article: widget.article,
                    categoryName: widget.categoryName,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RelatedArticlesSection extends StatefulWidget {
  final Article article;
  final String categoryName;

  const _RelatedArticlesSection({
    required this.article,
    required this.categoryName,
  });

  @override
  State<_RelatedArticlesSection> createState() =>
      _RelatedArticlesSectionState();
}

class _RelatedArticlesSectionState extends State<_RelatedArticlesSection> {
  late final Future<List<Article>> _relatedFuture;

  @override
  void initState() {
    super.initState();
    _relatedFuture = Provider.of<ArticleProvider>(context, listen: false)
        .getRelatedArticles(widget.article);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Article>>(
      future: _relatedFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 120,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        final related = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Related Articles',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 10),
            ...related.map((relatedArticle) => _RelatedArticleCard(
                  article: relatedArticle,
                  categoryName: widget.categoryName,
                ))
          ],
        );
      },
    );
  }
}

class _RelatedArticleCard extends StatefulWidget {
  final Article article;
  final String categoryName;

  const _RelatedArticleCard({
    required this.article,
    required this.categoryName,
  });

  @override
  State<_RelatedArticleCard> createState() => _RelatedArticleCardState();
}

class _RelatedArticleCardState extends State<_RelatedArticleCard> {
  late final Future<_CardDetails> _detailsFuture;

  @override
  void initState() {
    super.initState();
    _detailsFuture = _loadDetails();
  }

  Future<_CardDetails> _loadDetails() async {
    String imageUrl = widget.article.embeddedFeaturedMediaUrl ?? '';
    String authorName = widget.article.embeddedAuthorName ?? '';

    final futures = <Future<void>>[];
    if (imageUrl.isEmpty && widget.article.featuredMedia > 0) {
      futures.add(
        WpApiService.fetchFeaturedMediaUrl(widget.article.featuredMedia)
            .then((url) => imageUrl = url),
      );
    }
    if (authorName.isEmpty) {
      futures.add(
        WpApiService.fetchAuthorName(widget.article.link, widget.article.author)
            .then((name) => authorName = name),
      );
    }

    if (futures.isNotEmpty) {
      await Future.wait(futures);
    }
    return _CardDetails(imageUrl: imageUrl, authorName: authorName);
  }

  @override
  Widget build(BuildContext context) {
    final parsedDate = DateTime.tryParse(widget.article.date);
    final String formattedDate = parsedDate != null
        ? '⏰ ${DateFormat('MMMM d, y').format(parsedDate)}'
        : '';

    return FutureBuilder<_CardDetails>(
      future: _detailsFuture,
      builder: (context, snapshot) {
        final details = snapshot.data ??
            _CardDetails(
              imageUrl: widget.article.embeddedFeaturedMediaUrl ?? '',
              authorName: widget.article.embeddedAuthorName ?? '',
            );

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ArticleDetailScreen(
                  article: widget.article,
                  categoryName: widget.categoryName,
                  featuredMediaUrl: details.imageUrl,
                  authorName: details.authorName,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  NetworkImageWithFallback(
                    imageUrl: details.imageUrl,
                    fallbackAssetPath: 'assets/logo.png',
                    width: 110,
                    height: 110,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.article.title,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (formattedDate.isNotEmpty)
                          Text(
                            formattedDate,
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                        if (details.authorName.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            '👤 ${details.authorName}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CardDetails {
  final String imageUrl;
  final String authorName;
  const _CardDetails({required this.imageUrl, required this.authorName});
}
