import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/article.dart';
import '../providers/article_provider.dart';
import '../widgets/article_list.dart';
import '../widgets/offline_banner.dart';

class AuthorArticlesScreen extends StatefulWidget {
  final String authorName;
  final int? authorId;

  const AuthorArticlesScreen({
    super.key,
    required this.authorName,
    this.authorId,
  });

  @override
  State<AuthorArticlesScreen> createState() => _AuthorArticlesScreenState();
}

class _AuthorArticlesScreenState extends State<AuthorArticlesScreen> {
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
      final results = await provider.getArticlesByAuthor(
        widget.authorName,
        authorId: widget.authorId,
      );
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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.authorName),
        backgroundColor: colorScheme.surfaceContainerHighest,
        foregroundColor: colorScheme.onSurface,
      ),
      body: Column(
        children: [
          OfflineBanner(onRetry: _loadArticles),
          Center(
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
                            widget.authorName,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _isLoading
                                ? 'Loading articles...'
                                : '${_articles.length} ${_articles.length == 1 ? 'article' : 'articles'}',
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
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadArticles,
              child: ArticleList(
                categoryName: 'By ${widget.authorName}',
                articles: _articles,
                isLoading: _isLoading,
                errorMessage: _error,
                errorTitle: 'Failed to load author articles',
                emptyMessage: 'No articles found for "${widget.authorName}"',
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
