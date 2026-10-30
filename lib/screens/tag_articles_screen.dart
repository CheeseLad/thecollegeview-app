import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/article_provider.dart';
import '../models/article.dart';
import '../models/tag.dart';
import '../widgets/article_list.dart';
import '../widgets/offline_banner.dart';

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
      body: Column(
        children: [
          OfflineBanner(onRetry: _loadArticles),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadArticles,
              child: ArticleList(
                categoryName: widget.tag.name,
                articles: _articles,
                isLoading: _isLoading,
                errorMessage: _error,
                errorTitle: 'Failed to load tagged articles',
                emptyMessage: 'No articles found for tag "${widget.tag.name}"',
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
