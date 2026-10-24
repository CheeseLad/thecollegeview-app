import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/saved_articles_provider.dart';
import '../models/saved_article.dart';
import '../screens/article_detail_screen.dart';
import '../services/wp_api_service.dart';
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
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.bookmark_border,
                      size: 64,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No saved articles yet',
                      style: TextStyle(
                        fontSize: 18,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap the bookmark icon to save articles',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface,
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
                  final parsedDate = DateTime.tryParse(savedArticle.date);
                  final String formattedDate = parsedDate != null
                      ? '⏰ ${DateFormat('MMMM d, y').format(parsedDate)}'
                      : '';
                  final String savedDate =
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
    final savedArticle = widget.savedArticle;

    String imageUrl = savedArticle.featuredMediaUrl;
    if (imageUrl.isEmpty) {
      imageUrl =
          await WpApiService.fetchFeaturedMediaUrl(savedArticle.featuredMedia);
    }

    String authorName = savedArticle.authorName;
    if (authorName.isEmpty) {
      authorName = await WpApiService.fetchAuthorName(
          savedArticle.link, savedArticle.author);
    }

    return _SavedCardDetails(imageUrl: imageUrl, authorName: authorName);
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

          final details =
              snapshot.data ?? _SavedCardDetails(imageUrl: '', authorName: '');

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
                        featuredMediaUrl: widget.savedArticle.featuredMediaUrl,
                        authorName: widget.savedArticle.authorName,
                        tagNames: widget.savedArticle.tagNames,
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
                          featuredMediaUrl:
                              widget.savedArticle.featuredMediaUrl,
                          authorName: widget.savedArticle.authorName,
                          tagNames: widget.savedArticle.tagNames,
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
                  icon: Icon(
                    Icons.bookmark,
                    color: Theme.of(context).colorScheme.primary,
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
}

class _SavedCardDetails {
  final String imageUrl;
  final String authorName;

  _SavedCardDetails({required this.imageUrl, required this.authorName});
}
