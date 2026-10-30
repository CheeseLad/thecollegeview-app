import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/article.dart';
import '../providers/article_provider.dart';
import '../widgets/article_list.dart';
import '../widgets/offline_banner.dart';

class FilteredArticlesScreen extends StatefulWidget {
  final String title;
  final String categoryName;
  final String errorTitle;
  final String emptyMessage;
  final Future<List<Article>> Function(ArticleProvider provider) fetchArticles;
  final Widget Function(BuildContext context, bool isLoading, int count)?
      headerBuilder;

  const FilteredArticlesScreen({
    super.key,
    required this.title,
    required this.categoryName,
    required this.errorTitle,
    required this.emptyMessage,
    required this.fetchArticles,
    this.headerBuilder,
  });

  factory FilteredArticlesScreen.byTag({
    Key? key,
    required int tagId,
    required String tagName,
  }) {
    return FilteredArticlesScreen(
      key: key,
      title: 'Tag: $tagName',
      categoryName: tagName,
      errorTitle: 'Failed to load tagged articles',
      emptyMessage: 'No articles found for tag "$tagName"',
      fetchArticles: (provider) => provider.getArticlesByTag(tagId),
    );
  }

  factory FilteredArticlesScreen.byAuthor({
    Key? key,
    required String authorName,
    int? authorId,
  }) {
    return FilteredArticlesScreen(
      key: key,
      title: authorName,
      categoryName: 'By $authorName',
      errorTitle: 'Failed to load author articles',
      emptyMessage: 'No articles found for "$authorName"',
      fetchArticles: (provider) => provider.getArticlesByAuthor(
        authorName,
        authorId: authorId,
      ),
      headerBuilder: (context, isLoading, count) => _AuthorHeader(
        authorName: authorName,
        isLoading: isLoading,
        articleCount: count,
      ),
    );
  }

  @override
  State<FilteredArticlesScreen> createState() => _FilteredArticlesScreenState();
}

class _FilteredArticlesScreenState extends State<FilteredArticlesScreen> {
  List<Article> _articles = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadArticles();
  }

  Future<void> _loadArticles() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final provider = Provider.of<ArticleProvider>(context, listen: false);
      final results = await widget.fetchArticles(provider);
      if (!mounted) return;
      setState(() {
        _articles = results;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          OfflineBanner(onRetry: _loadArticles),
          if (widget.headerBuilder != null)
            widget.headerBuilder!(context, _isLoading, _articles.length),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadArticles,
              child: ArticleList(
                categoryName: widget.categoryName,
                articles: _articles,
                isLoading: _isLoading,
                errorMessage: _error,
                errorTitle: widget.errorTitle,
                emptyMessage: widget.emptyMessage,
                emptyIcon: Icons.article_outlined,
                onRetry: _loadArticles,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthorHeader extends StatelessWidget {
  final String authorName;
  final bool isLoading;
  final int articleCount;

  const _AuthorHeader({
    required this.authorName,
    required this.isLoading,
    required this.articleCount,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                child: const Icon(Icons.person, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      authorName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isLoading
                          ? 'Loading articles...'
                          : '$articleCount ${articleCount == 1 ? 'article' : 'articles'}',
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

