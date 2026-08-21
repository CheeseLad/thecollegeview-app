import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../providers/saved_articles_provider.dart';
import '../models/saved_article.dart';
import '../screens/article_detail_screen.dart';
import '../services/wp_api_service.dart';
import '../utils/html_utils.dart';
import '../widgets/network_image_with_fallback.dart';

class SavedArticlesScreen extends StatelessWidget {
  const SavedArticlesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final savedArticlesProvider = Provider.of<SavedArticlesProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Articles'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await savedArticlesProvider.refreshSavedArticles();
        },
        child: savedArticlesProvider.savedArticles.isEmpty
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.bookmark_border,
                      size: 64,
                      color: Colors.black87,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No saved articles yet',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Tap the bookmark icon to save articles',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                itemCount: savedArticlesProvider.savedArticles.length,
                itemBuilder: (context, index) {
                  SavedArticle savedArticle =
                      savedArticlesProvider.savedArticles[index];
                  String formattedDate =
                      '⏰ ${DateFormat('MMMM d, y').format(DateTime.parse(savedArticle.date))}';
                  String savedDate =
                      '💾 Saved ${DateFormat('MMM d, y').format(savedArticle.savedAt)}';

                  return _SavedArticleCard(
                    savedArticle: savedArticle,
                    formattedDate: formattedDate,
                    savedDate: savedDate,
                    onRemove: () =>
                        savedArticlesProvider.removeArticle(savedArticle.id),
                  );
                },
              ),
      ),
    );
  }
}

class _SavedArticleCard extends StatefulWidget {
  final SavedArticle savedArticle;
  final String formattedDate;
  final String savedDate;
  final VoidCallback onRemove;

  const _SavedArticleCard({
    required this.savedArticle,
    required this.formattedDate,
    required this.savedDate,
    required this.onRemove,
  });

  @override
  State<_SavedArticleCard> createState() => _SavedArticleCardState();
}

class _SavedArticleCardState extends State<_SavedArticleCard> {
  late final Future<_SavedCardDetails> _detailsFuture;

  @override
  void initState() {
    super.initState();
    _detailsFuture = _loadDetails();
  }

  Future<_SavedCardDetails> _loadDetails() async {
    final results = await Future.wait([
      fetchFeaturedMedia(widget.savedArticle.featured_media),
      fetchAuthorName(
          widget.savedArticle.link, widget.savedArticle.author),
    ]);
    return _SavedCardDetails(
        imageUrl: results[0], authorName: results[1]);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(10),
      child: FutureBuilder<_SavedCardDetails>(
        future: _detailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              height: 150,
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final details = snapshot.data ??
              _SavedCardDetails(imageUrl: '', authorName: '');

          return Padding(
            padding: const EdgeInsets.all(15.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ArticleDetailScreen(
                        article: widget.savedArticle.toArticle(),
                        categoryName: widget.savedArticle.categoryName,
                      ),
                    ),
                  ),
                  child: NetworkImageWithFallback(
                    imageUrl: details.imageUrl,
                    fallbackAssetPath: 'assets/logo.png',
                    width: 125,
                    height: 125,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ArticleDetailScreen(
                          article: widget.savedArticle.toArticle(),
                          categoryName: widget.savedArticle.categoryName,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.savedArticle.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.formattedDate),
                            const SizedBox(height: 5),
                            Text(widget.savedDate),
                            const SizedBox(height: 5),
                            Text('👤 ${details.authorName}'),
                          ],
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.bookmark,
                    color: Colors.blue,
                  ),
                  onPressed: widget.onRemove,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<String> fetchAuthorName(String articleUrl, int authorId) async {
    final authorName = await WpApiService.fetchAuthorInfo(articleUrl, authorId);
    return HtmlUtils.decodeHtmlEntities(authorName);
  }

  Future<String> fetchFeaturedMedia(int mediaId) async {
    try {
      final response = await WpApiService.get(
          Uri.parse('https://tcvappapi.jakefarrell.ie/wp-json/wp/v2/media/$mediaId'));

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
}

class _SavedCardDetails {
  final String imageUrl;
  final String authorName;

  _SavedCardDetails({required this.imageUrl, required this.authorName});
}
