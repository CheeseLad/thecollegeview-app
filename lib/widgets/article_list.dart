import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../providers/article_provider.dart';
import '../models/article.dart';
import '../screens/article_detail_screen.dart';
import '../services/wp_api_service.dart';
import '../utils/html_utils.dart';
import '../config/app_urls.dart';
import 'network_image_with_fallback.dart';

class ArticleList extends StatefulWidget {
  final String categoryName;

  const ArticleList({super.key, required this.categoryName});

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
    final articleProvider = Provider.of<ArticleProvider>(context, listen: false);
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
    final articleProvider = Provider.of<ArticleProvider>(context);

    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: articleProvider.articles.length + (articleProvider.loading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= articleProvider.articles.length) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final article = articleProvider.articles[index];
        return _ArticleCard(
          key: ValueKey(article.id),
          article: article,
          categoryName: widget.categoryName,
        );
      },
    );
  }
}

class _ArticleCard extends StatefulWidget {
  final Article article;
  final String categoryName;

  const _ArticleCard({
    super.key,
    required this.article,
    required this.categoryName,
  });

  @override
  State<_ArticleCard> createState() => _ArticleCardState();
}

class _ArticleCardState extends State<_ArticleCard> {
  late final Future<_CardDetails> _detailsFuture;

  @override
  void initState() {
    super.initState();
    _detailsFuture = _loadDetails();
  }

  Future<_CardDetails> _loadDetails() async {
    final results = await Future.wait([
      _fetchFeaturedMedia(widget.article.featured_media),
      _fetchAuthorName(widget.article.link, widget.article.author),
    ]);
    return _CardDetails(imageUrl: results[0], authorName: results[1]);
  }

  @override
  Widget build(BuildContext context) {
    final String formattedDate =
        '⏰ ${DateFormat('MMMM d, y').format(DateTime.parse(widget.article.date))}';

    return Card(
      margin: const EdgeInsets.all(10),
      child: FutureBuilder<_CardDetails>(
        future: _detailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              height: 150,
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final details =
              snapshot.data ?? _CardDetails(imageUrl: '', authorName: '');

          return InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ArticleDetailScreen(
                  article: widget.article,
                  categoryName: widget.categoryName,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  NetworkImageWithFallback(
                    imageUrl: details.imageUrl,
                    fallbackAssetPath: 'assets/logo.png',
                    width: 125,
                    height: 125,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SelectableText(widget.article.title,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SelectableText(formattedDate),
                            const SizedBox(height: 5),
                            SelectableText('👤 ${details.authorName}'),
                          ],
                        ),
                        const SizedBox(height: 10),
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

Future<String> _fetchAuthorName(String articleUrl, int authorId) async {
  final authorName = await WpApiService.fetchAuthorInfo(articleUrl, authorId);
  return HtmlUtils.decodeHtmlEntities(authorName);
}

Future<String> _fetchFeaturedMedia(int mediaId) async {
  try {
    final response = await WpApiService.get(
        Uri.parse('${AppUrls.apiBase}/wp-json/wp/v2/media/$mediaId'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['source_url'] ?? '';
    } else {
      return '';
    }
  } catch (e) {
    return '';
  }
}
