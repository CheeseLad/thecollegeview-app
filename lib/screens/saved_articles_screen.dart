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
                SavedArticle savedArticle = savedArticlesProvider.savedArticles[index];
                String formattedDate =
                    '⏰ ${DateFormat('MMMM d, y').format(DateTime.parse(savedArticle.date))}';
                String savedDate =
                    '💾 Saved ${DateFormat('MMM d, y').format(savedArticle.savedAt)}';

                return Card(
                  margin: const EdgeInsets.all(10),
                  child: Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ArticleDetailScreen(
                                article: savedArticle.toArticle(),
                                categoryName: savedArticle.categoryName,
                              ),
                            ),
                          ),
                          child: FutureBuilder<String>(
                            future: fetchFeaturedMedia(savedArticle.featured_media),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return Container(
                                  width: 125,
                                  height: 125,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              } else {
                                return NetworkImageWithFallback(
                                  imageUrl: snapshot.data ?? '',
                                  fallbackAssetPath: 'assets/logo.png',
                                  width: 125,
                                  height: 125,
                                  borderRadius: BorderRadius.circular(8),
                                );
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ArticleDetailScreen(
                                  article: savedArticle.toArticle(),
                                  categoryName: savedArticle.categoryName,
                                ),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  savedArticle.title,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(formattedDate),
                                    const SizedBox(height: 5),
                                    Text(savedDate),
                                    const SizedBox(height: 5),
                                    FutureBuilder<String>(
                                      future: fetchAuthorName(savedArticle.author),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState ==
                                            ConnectionState.waiting) {
                                          return const CircularProgressIndicator();
                                        } else if (snapshot.hasError) {
                                          return const Text('Error');
                                        } else {
                                          return Text('👤 ${snapshot.data}');
                                        }
                                      },
                                    ),
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
                          onPressed: () {
                            savedArticlesProvider.removeArticle(savedArticle.id);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      ),
    );
  }

  Future<String> fetchAuthorName(int authorId) async {
    final response = await WpApiService.get(
        Uri.parse('https://thecollegeview.ie/wp-json/wp/v2/users/$authorId'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return HtmlUtils.decodeHtmlEntities(data['name']);
    } else {
      throw Exception('Failed to load author');
    }
  }

  Future<String> fetchFeaturedMedia(int mediaId) async {
    try {
      final response = await WpApiService.get(
          Uri.parse('https://thecollegeview.ie/wp-json/wp/v2/media/$mediaId'));

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
