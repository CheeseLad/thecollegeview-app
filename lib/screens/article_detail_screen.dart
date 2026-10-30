import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:share_plus/share_plus.dart';
import '../config/app_config.dart';
import '../models/article.dart';
import '../providers/article_provider.dart';
import '../providers/saved_articles_provider.dart';
import '../theme/app_theme.dart';
import '../services/wp_api_service.dart';
import '../utils/deep_link_handler.dart';
import '../widgets/network_image_with_fallback.dart';
import '../widgets/article_list.dart';
import '../widgets/fullscreen_image_viewer.dart';
import '../widgets/offline_banner.dart';
import '../widgets/skeleton.dart';
import 'filtered_articles_screen.dart';

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
  String _authorName = '';
  String _featuredMediaUrl = '';
  List<String> _tagNames = const [];
  bool _isReady = false;
  bool _isLoading = false;

  final GlobalKey _shareButtonKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _authorName =
        WpApiService.getInitialAuthorName(widget.article, widget.authorName) ??
            '';
    _featuredMediaUrl = WpApiService.getInitialFeaturedMediaUrl(
            widget.article, widget.featuredMediaUrl) ??
        '';
    _tagNames =
        WpApiService.getInitialTagNames(widget.article.tags, widget.tagNames) ??
            const [];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isReady && !_isLoading) {
      _resolveOrLoadArticleDetails();
    }
  }

  void _resolveOrLoadArticleDetails() {
    final hasFeaturedMedia =
        widget.article.featuredMedia > 0 || _featuredMediaUrl.isNotEmpty;
    final hasResolvedMedia = !hasFeaturedMedia ||
        (_featuredMediaUrl.isNotEmpty &&
            NetworkImageWithFallback.isPreloaded(
              context,
              _featuredMediaUrl,
              width: double.infinity,
              height: 220,
            ));
    final hasResolvedAuthor = _authorName.isNotEmpty;
    final hasResolvedTags =
        WpApiService.getInitialTagNames(widget.article.tags, widget.tagNames) !=
            null;

    if (hasResolvedMedia && hasResolvedAuthor && hasResolvedTags) {
      _isReady = true;
    } else {
      _loadAllDetails();
    }
  }

  Future<void> _loadAllDetails() async {
    _isLoading = true;
    final tagFuture = (widget.tagNames != null && widget.tagNames!.isNotEmpty)
        ? Future.value(widget.tagNames!)
        : WpApiService.fetchTagNames(widget.article.tags);

    final results = await Future.wait([
      WpApiService.resolveAuthorName(widget.article, widget.authorName),
      WpApiService.resolveFeaturedMediaUrl(
          widget.article, widget.featuredMediaUrl),
      tagFuture,
    ]);

    if (!mounted) return;

    final resolvedAuthor = (results[0] as String).trim();
    final resolvedMediaUrl = (results[1] as String).trim();
    final resolvedTags = results[2] as List<String>;

    if (resolvedMediaUrl.isNotEmpty) {
      await NetworkImageWithFallback.preload(
        context,
        resolvedMediaUrl,
        width: double.infinity,
        height: 220,
      );
    }

    if (!mounted) return;

    setState(() {
      _authorName = resolvedAuthor.isNotEmpty
          ? resolvedAuthor
          : WpApiService.fallbackAuthorName;
      _featuredMediaUrl = resolvedMediaUrl;
      _tagNames = resolvedTags;
      _isReady = true;
      _isLoading = false;
    });
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
                            onChanged: themeProvider.setArticleFontSize,
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
        builder: (context) => FilteredArticlesScreen.byAuthor(
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

  Widget _buildTagChips(BuildContext context, List<String> tagNames) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 20),
      child: Wrap(
        spacing: 8.0,
        runSpacing: 4.0,
        children: tagNames.asMap().entries.map((entry) {
          final tagId = widget.article.tags[entry.key];
          final tagName = entry.value;

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FilteredArticlesScreen.byTag(
                    tagId: tagId,
                    tagName: tagName,
                  ),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colorScheme.primary),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    tagName,
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final config = AppConfig.instance;
    final formattedDate = widget.article.formattedDate;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: AppTheme.articleDetailBackgroundColor(context),
      appBar: AppBar(
        title: Text(widget.article.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.format_size),
            tooltip: 'Text size',
            onPressed: () => _showFontSizeSheet(context),
          ),
          if (config.enableShareButton)
            IconButton(
              key: _shareButtonKey,
              icon: const FaIcon(FontAwesomeIcons.arrowUpFromBracket, size: 19),
              tooltip: 'Share',
              onPressed: _shareArticle,
            ),
          Padding(
            padding: const EdgeInsets.only(right: 4.0),
            child: Selector<SavedArticlesProvider, bool>(
              selector: (_, provider) =>
                  provider.isArticleSaved(widget.article.id),
              builder: (context, isSaved, _) {
                return IconButton(
                  icon: Icon(
                    isSaved ? Icons.bookmark : Icons.bookmark_border,
                    color: isSaved
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                  ),
                  onPressed: () => context
                      .read<SavedArticlesProvider>()
                      .toggleSaveArticle(widget.article, widget.categoryName),
                );
              },
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: !_isReady
                ? const ArticleDetailSkeleton()
                : SingleChildScrollView(
                    child: SelectionArea(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _CenteredContentSection(
                            color:
                                AppTheme.articleDetailBackgroundColor(context),
                            padding: const EdgeInsets.fromLTRB(15, 15, 15, 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Selector<ThemeProvider, double>(
                                  selector: (_, tp) => tp.articleFontSize,
                                  builder: (context, articleFontSize, _) {
                                    return Text(
                                      widget.article.title,
                                      style: TextStyle(
                                        fontSize: articleFontSize + 8,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 10),
                                if (formattedDate.isNotEmpty)
                                  Text(
                                    formattedDate,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                _buildTappableAuthorChip(
                                  context,
                                  _authorName.isNotEmpty
                                      ? _authorName
                                      : WpApiService.fallbackAuthorName,
                                ),
                                Text(
                                  '📂 ${widget.categoryName}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                if (_featuredMediaUrl.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 20),
                                    child: GestureDetector(
                                      onTap: () => FullscreenImageViewer.show(
                                        context,
                                        imageUrl: _featuredMediaUrl,
                                        caption: widget.article.title,
                                      ),
                                      child: NetworkImageWithFallback(
                                        imageUrl: _featuredMediaUrl,
                                        fallbackAssetPath: config.logoAssetPath,
                                        width: double.infinity,
                                        height: 220,
                                        fit: BoxFit.cover,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                Selector<ThemeProvider, double>(
                                  selector: (_, tp) => tp.articleFontSize,
                                  builder: (context, articleFontSize, _) {
                                    return HtmlWidget(
                                      widget.article.content,
                                      renderMode: RenderMode.column,
                                      textStyle: TextStyle(
                                        fontSize: articleFontSize,
                                        height: 1.5,
                                      ),
                                      onTapUrl: (url) =>
                                          DeepLinkHandler.handleTappedUrl(
                                              context, url),
                                      customStylesBuilder: (element) =>
                                          AppTheme.editorialHtmlStyles(
                                              context, element.localName),
                                      customWidgetBuilder: (element) {
                                        if (element.localName == 'img') {
                                          final src = element.attributes['src'];
                                          if (src != null && src.isNotEmpty) {
                                            final alt = element
                                                .attributes['alt']
                                                ?.trim();
                                            final figCaption = element.parent
                                                ?.querySelector('figcaption')
                                                ?.text
                                                .trim();
                                            final caption =
                                                (alt != null && alt.isNotEmpty)
                                                    ? alt
                                                    : figCaption;
                                            return GestureDetector(
                                              onTap: () =>
                                                  FullscreenImageViewer.show(
                                                context,
                                                imageUrl: src,
                                                caption: caption,
                                              ),
                                              child: NetworkImageWithFallback(
                                                imageUrl: src,
                                                fallbackAssetPath:
                                                    config.logoAssetPath,
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                            );
                                          }
                                        }
                                        return null;
                                      },
                                    );
                                  },
                                ),
                                const SizedBox(height: 10),
                                if (config.enableTagChips &&
                                    _tagNames.isNotEmpty)
                                  _buildTagChips(context, _tagNames),
                              ],
                            ),
                          ),
                          if (config.enableRelatedArticles)
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

class _CenteredContentSection extends StatelessWidget {
  final Color color;
  final EdgeInsetsGeometry padding;
  final Widget child;

  const _CenteredContentSection({
    required this.color,
    required this.padding,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color,
      padding: padding,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: child,
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
  late final Future<List<Article>> _relatedFuture =
      Provider.of<ArticleProvider>(context, listen: false)
          .getRelatedArticles(widget.article);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Article>>(
      future: _relatedFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const RelatedArticlesSkeleton();
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        final related = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _CenteredContentSection(
              color: AppTheme.articleDetailBackgroundColor(context),
              padding: const EdgeInsets.fromLTRB(15, 0, 15, 8),
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
            _CenteredContentSection(
              color: Theme.of(context).scaffoldBackgroundColor,
              padding: const EdgeInsets.fromLTRB(15, 12, 15, 20),
              child: SkeletonShimmer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: related
                      .map((relatedArticle) => ArticleCard(
                            key: ValueKey(relatedArticle.id),
                            article: relatedArticle,
                            categoryName: widget.categoryName,
                            margin: const EdgeInsets.only(bottom: 10),
                          ))
                      .toList(),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
