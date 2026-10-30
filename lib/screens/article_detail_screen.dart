import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../config/app_config.dart';
import '../models/article.dart';
import '../models/tag.dart';
import '../providers/article_provider.dart';
import '../providers/saved_articles_provider.dart';
import '../theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:share_plus/share_plus.dart';
import '../services/wp_api_service.dart';
import '../utils/deep_link_handler.dart';
import '../widgets/network_image_with_fallback.dart';
import '../widgets/article_list.dart';
import '../widgets/fullscreen_image_viewer.dart';
import '../widgets/offline_banner.dart';
import 'author_articles_screen.dart';
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
    _authorNameFuture =
        WpApiService.resolveAuthorName(widget.article, widget.authorName);
    _featuredMediaUrlFuture = WpApiService.resolveFeaturedMediaUrl(
        widget.article, widget.featuredMediaUrl);
    _tagNamesFuture = (widget.tagNames != null && widget.tagNames!.isNotEmpty)
        ? Future.value(widget.tagNames!)
        : WpApiService.fetchTagNames(widget.article.tags);
  }

  void _showFontSizeSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return Consumer<ThemeProvider>(
          builder: (context, themeProvider, _) {
            const presets = <String, double>{
              'Small': 14.0,
              'Medium': 16.0,
              'Large': 19.0,
              'Extra Large': 22.0,
            };

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Reader Font Size',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${themeProvider.articleFontSize.round()} pt (${themeProvider.articleFontSizeLabel})',
                          style: TextStyle(
                            fontSize: 14,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: presets.entries.map((entry) {
                        final isSelected =
                            (themeProvider.articleFontSize - entry.value)
                                    .abs() <
                                0.5;
                        return ChoiceChip(
                          label: Text(entry.key),
                          selected: isSelected,
                          onSelected: (_) {
                            themeProvider.setArticleFontSize(entry.value);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text('A', style: TextStyle(fontSize: 13)),
                        Expanded(
                          child: Slider(
                            value: themeProvider.articleFontSize,
                            min: ThemeProvider.minFontSize,
                            max: ThemeProvider.maxFontSize,
                            divisions: 11,
                            label: '${themeProvider.articleFontSize.round()}',
                            onChanged: (value) {
                              themeProvider.setArticleFontSize(value);
                            },
                          ),
                        ),
                        const Text(
                          'A',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openAuthorArticles(String authorName) {
    final trimmed = authorName.trim();
    if (trimmed.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AuthorArticlesScreen(
          authorName: trimmed,
          authorId: widget.article.author,
        ),
      ),
    );
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

  Widget _buildTappableAuthorChip(BuildContext context, String author) {
    if (!AppConfig.instance.enableAuthorTap) {
      return Text(
        '👤 $author',
        style: TextStyle(
          fontSize: 16,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
    }

    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => _openAuthorArticles(author),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                '👤 $author',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.primary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right,
              size: 18,
              color: colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final parsedDate = DateTime.tryParse(widget.article.date);
    final String formattedDate = parsedDate != null
        ? '⏰ ${DateFormat('MMMM d, y').format(parsedDate)}'
        : '';
    final savedArticlesProvider = Provider.of<SavedArticlesProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.articleDetailBackgroundColor(context),
      appBar: AppBar(
        title: Text(widget.article.title),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        actions: [
          IconButton(
            icon: const Icon(Icons.format_size),
            tooltip: 'Text size',
            onPressed: () => _showFontSizeSheet(context),
          ),
          IconButton(
            key: _shareButtonKey,
            icon: const FaIcon(FontAwesomeIcons.arrowUpFromBracket, size: 19),
            tooltip: 'Share',
            onPressed: _shareArticle,
          ),
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
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: SingleChildScrollView(
              child: SelectionArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      color: AppTheme.articleDetailBackgroundColor(context),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 900),
                          child: Padding(
                            padding:
                                const EdgeInsets.fromLTRB(15.0, 15.0, 15.0, 20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.article.title,
                                  style: TextStyle(
                                    fontSize: themeProvider.articleFontSize + 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                          const SizedBox(height: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (formattedDate.isNotEmpty)
                                Text(
                                  formattedDate,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                                ),
                              FutureBuilder<String>(
                                future: _authorNameFuture,
                                initialData: WpApiService.getInitialAuthorName(
                                    widget.article, widget.authorName),
                                builder: (context, snapshot) {
                                  final author = snapshot.data ?? '';
                                  if (author.isEmpty) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2),
                                      );
                                    }
                                    return _buildTappableAuthorChip(
                                      context,
                                      WpApiService.fallbackAuthorName,
                                    );
                                  }
                                  return _buildTappableAuthorChip(
                                    context,
                                    author,
                                  );
                                },
                              ),
                              Text(
                                '📂 ${widget.categoryName.replaceFirst(RegExp(r'^Tag:\s*', caseSensitive: false), '')}',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          // Display featured media if available (tap to fullscreen zoom)
                          if (widget.article.featuredMedia > 0 ||
                              (widget.article.embeddedFeaturedMediaUrl !=
                                      null &&
                                  widget.article.embeddedFeaturedMediaUrl!
                                      .isNotEmpty))
                            FutureBuilder<String>(
                              future: _featuredMediaUrlFuture,
                              initialData:
                                  WpApiService.getInitialFeaturedMediaUrl(
                                      widget.article, widget.featuredMediaUrl),
                              builder: (context, snapshot) {
                                final mediaUrl = snapshot.data ?? '';
                                if (mediaUrl.isNotEmpty) {
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 20),
                                    child: GestureDetector(
                                      onTap: () => FullscreenImageViewer.show(
                                        context,
                                        imageUrl: mediaUrl,
                                        caption: widget.article.title,
                                      ),
                                      child: NetworkImageWithFallback(
                                        imageUrl: mediaUrl,
                                        fallbackAssetPath: 'assets/logo.png',
                                        width: double.infinity,
                                        height: 220,
                                        fit: BoxFit.cover,
                                        borderRadius:
                                            BorderRadius.circular(10),
                                      ),
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
                            textStyle: TextStyle(
                              fontSize: themeProvider.articleFontSize,
                              height: 1.5,
                            ),
                            onTapUrl: (url) =>
                                DeepLinkHandler.handleTappedUrl(context, url),
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
                                final alt = element.attributes['alt'];
                                if (src != null && src.isNotEmpty) {
                                  return GestureDetector(
                                    onTap: () => FullscreenImageViewer.show(
                                      context,
                                      imageUrl: src,
                                      caption: alt,
                                    ),
                                    child: NetworkImageWithFallback(
                                      imageUrl: src,
                                      fallbackAssetPath: 'assets/logo.png',
                                      borderRadius: BorderRadius.circular(10),
                                    ),
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
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
                                            final tagId =
                                                widget.article.tags[index];

                                            return GestureDetector(
                                              onTap: () {
                                                final tag = Tag(
                                                  id: tagId,
                                                  name: tagName,
                                                );

                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        TagArticlesScreen(
                                                            tag: tag),
                                                  ),
                                                );
                                              },
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
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
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      tagName,
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .onPrimaryContainer,
                                                        fontWeight:
                                                            FontWeight.w500,
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
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                _RelatedArticlesSection(
                  article: widget.article,
                  categoryName: widget.categoryName,
                ),
                  ],
                ),
              ),
            ),
          ),
        ],
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: AppTheme.articleDetailBackgroundColor(context),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Padding(
                    padding:
                        const EdgeInsets.fromLTRB(15.0, 0.0, 15.0, 8.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Related Articles',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              padding: const EdgeInsets.fromLTRB(15.0, 12.0, 15.0, 20.0),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...related.map((relatedArticle) => ArticleCard(
                            key: ValueKey(relatedArticle.id),
                            article: relatedArticle,
                            categoryName: widget.categoryName,
                            margin: const EdgeInsets.only(bottom: 10),
                          )),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
