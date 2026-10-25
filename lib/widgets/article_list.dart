import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/article_provider.dart';
import '../models/article.dart';
import '../screens/article_detail_screen.dart';
import '../services/wp_api_service.dart';
import '../widgets/network_image_with_fallback.dart';

class ArticleList extends StatefulWidget {
  final String categoryName;
  final List<Article>? articles;
  final VoidCallback? onRetry;

  const ArticleList({
    super.key,
    required this.categoryName,
    this.articles,
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
    if (widget.articles != null) {
      final list = widget.articles!;
      if (list.isEmpty) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No articles found.',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          ),
        );
      }
      return ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final article = list[index];
          return ArticleCard(
            key: ValueKey(article.id),
            article: article,
            categoryName: widget.categoryName,
          );
        },
      );
    }

    final articleProvider = Provider.of<ArticleProvider>(context);

    if (articleProvider.error != null && articleProvider.articles.isEmpty) {
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
                'Failed to load articles',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                articleProvider.error!,
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
                onPressed: () {
                  if (widget.onRetry != null) {
                    widget.onRetry!();
                  } else {
                    articleProvider.refreshArticles();
                  }
                },
              ),
            ],
          ),
        ),
      );
    }

    if (articleProvider.articles.isEmpty && !articleProvider.loading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.article_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                'No articles available in this section.',
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

    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount:
          articleProvider.articles.length + (articleProvider.loading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= articleProvider.articles.length) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final article = articleProvider.articles[index];
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

  const ArticleCard({
    super.key,
    required this.article,
    required this.categoryName,
    this.margin,
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
    final initialImageUrl = (widget.article.embeddedFeaturedMediaUrl != null &&
            widget.article.embeddedFeaturedMediaUrl!.isNotEmpty)
        ? widget.article.embeddedFeaturedMediaUrl!
        : (WpApiService.getCachedFeaturedMediaUrl(
                widget.article.featuredMedia) ??
            '');

    final initialAuthorName =
        WpApiService.getCachedAuthorName(widget.article.link) ??
            widget.article.embeddedAuthorName ??
            '';

    _currentDetails = _CardDetails(
      imageUrl: initialImageUrl,
      authorName: initialAuthorName,
    );

    _detailsFuture = _loadDetails();
  }

  Future<_CardDetails> _loadDetails() async {
    String imageUrl = _currentDetails.imageUrl;
    String authorName = _currentDetails.authorName;

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

    final details = _CardDetails(imageUrl: imageUrl, authorName: authorName);
    if (mounted) {
      _currentDetails = details;
    }
    return details;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final parsedDate = DateTime.tryParse(widget.article.date);
    final String formattedDate = parsedDate != null
        ? '⏰ ${DateFormat('MMMM d, y').format(parsedDate)}'
        : '';

    return Card(
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
          );
        },
      ),
    );
  }
}

class _CardDetails {
  final String imageUrl;
  final String authorName;

  _CardDetails({required this.imageUrl, required this.authorName});
}
