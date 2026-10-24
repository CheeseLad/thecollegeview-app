import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/article_provider.dart';
import '../models/article.dart';
import '../models/tag.dart';
import '../widgets/article_list.dart';

class TagArticlesScreen extends StatefulWidget {
  final Tag tag;

  const TagArticlesScreen({super.key, required this.tag});

  @override
  State<TagArticlesScreen> createState() => _TagArticlesScreenState();
}

class _TagArticlesScreenState extends State<TagArticlesScreen> {
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
      final results = await provider.getArticlesByTag(widget.tag.id);
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
        title: Text('Tag: ${widget.tag.name}'),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: RefreshIndicator(
        onRefresh: _loadArticles,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
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
                'Failed to load tagged articles',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
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
                onPressed: _loadArticles,
              ),
            ],
          ),
        ),
      );
    }

    if (_articles.isEmpty) {
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
                'No articles found for tag "${widget.tag.name}"',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ArticleList(
      categoryName: 'Tag: ${widget.tag.name}',
      articles: _articles,
    );
  }
}
