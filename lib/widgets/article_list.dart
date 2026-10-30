import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/article_provider.dart';
import '../models/article.dart';
import '../screens/article_detail_screen.dart';
import '../services/wp_api_service.dart';
import '../widgets/network_image_with_fallback.dart';
import 'skeleton.dart';

class ArticleList extends StatefulWidget {
  final String categoryName;
  final List<Article>? articles;
  final bool? isLoading;
  final String? errorMessage;
  final String errorTitle;
  final String? emptyMessage;
  final IconData? emptyIcon;
  final VoidCallback? onRetry;

  const ArticleList({
    super.key,
    required this.categoryName,
    this.articles,
    this.isLoading,
    this.errorMessage,
    this.errorTitle = 'Failed to load articles',
    this.emptyMessage,
    this.emptyIcon,
    this.onRetry,
  });

  @override
  State<ArticleList> createState() => _ArticleListState();
}

class _ArticleListState extends State<ArticleList> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Only paginate when using the provider's articles
    if (widget.articles != null) return;

    final articleProvider =
        Provider.of<ArticleProvider>(context, listen: false);
    if (articleProvider.loading) return;

    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (articleProvider.currentPage < articleProvider.totalPages) {
        articleProvider.nextPage();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final usesCustomList = widget.articles != null;
    final articleProvider = usesCustomList
        ? Provider.of<ArticleProvider>(context, listen: false)
        : Provider.of<ArticleProvider>(context);

    final list = widget.articles ?? articleProvider.articles;
    final loading = widget.isLoading ?? (usesCustomList ? false : articleProvider.loading);
    final error = widget.errorMessage ?? (usesCustomList ? null : articleProvider.error);

    if (loading && list.isEmpty) {
      return const ArticleListSkeleton();
    }

    if (error != null && list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                widget.errorTitle,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                onPressed: widget.onRetry ?? articleProvider.refreshArticles,
              ),
            ],
          ),
        ),
      );
    }

    if (list.isEmpty) {
      final icon = widget.emptyIcon ??
          (usesCustomList ? Icons.search_off : Icons.article_outlined);
      final message = widget.emptyMessage ??
          (usesCustomList
              ? 'No articles found.'
              : 'No articles available in this section.');

      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 64,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final showBottomLoader = !usesCustomList && loading;

    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: list.length + (showBottomLoader ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= list.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 4.0),
            child: ArticleCardSkeleton(),
          );
        }
        final article = list[index];
        return ArticleCard(
          key: ValueKey(article.id),
          article: article,
          categoryName: widget.categoryName,
        );
      },
    );
  }
}

class ArticleCard extends StatefulWidget {
  final Article article;
  final String categoryName;
  final EdgeInsetsGeometry? margin;
  final DateTime? savedAt;
  final List<String>? tagNames;
  final VoidCallback? onRemove;

  const ArticleCard({
    super.key,
    required this.article,
    required this.categoryName,
    this.margin,
    this.savedAt,
    this.tagNames,
    this.onRemove,
  });

  @override
  State<ArticleCard> createState() => _ArticleCardState();
}

class _ArticleCardState extends State<ArticleCard>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late final Future<_CardDetails> _detailsFuture;
  late _CardDetails _currentDetails;

  @override
  void initState() {
    super.initState();
    _currentDetails = _CardDetails(
      imageUrl: WpApiService.getInitialFeaturedMediaUrl(widget.article) ?? '',
      authorName: WpApiService.getInitialAuthorName(widget.article) ?? '',
    );
    _detailsFuture = _loadDetails();
  }

  Future<_CardDetails> _loadDetails() async {
    final results = await Future.wait([
      WpApiService.resolveFeaturedMediaUrl(
          widget.article, _currentDetails.imageUrl),
      WpApiService.resolveAuthorName(
          widget.article, _currentDetails.authorName),
    ]);

    final details = _CardDetails(imageUrl: results[0], authorName: results[1]);
    if (mounted) {
      _currentDetails = details;
    }
    return details;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final formattedDate = widget.article.formattedDate;
    final String? savedDate = widget.savedAt != null
        ? '💾 Saved ${DateFormat('MMM d, y').format(widget.savedAt!)}'
        : null;
    final subtextStyle = TextStyle(
      fontSize: 13,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Card(
          margin: widget.margin ??
              const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: FutureBuilder<_CardDetails>(
            future: _detailsFuture,
            initialData: _currentDetails,
            builder: (context, snapshot) {
              final details = snapshot.data ?? _currentDetails;

              return InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ArticleDetailScreen(
                      article: widget.article,
                      categoryName: widget.categoryName,
                      featuredMediaUrl: details.imageUrl,
                      authorName: details.authorName,
                      tagNames: widget.tagNames,
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
                              Text(formattedDate, style: subtextStyle),
                            if (savedDate != null) ...[
                              const SizedBox(height: 4),
                              Text(savedDate, style: subtextStyle),
                            ],
                            if (details.authorName.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                '👤 ${details.authorName}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: subtextStyle,
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (widget.onRemove != null)
                        IconButton(
                          icon: Icon(
                            Icons.bookmark,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          onPressed: widget.onRemove,
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CardDetails {
  final String imageUrl;
  final String authorName;

  _CardDetails({required this.imageUrl, required this.authorName});
}
