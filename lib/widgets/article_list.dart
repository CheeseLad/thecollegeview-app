import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../providers/article_provider.dart';
import '../providers/saved_articles_provider.dart';
import '../models/article.dart';
import '../screens/article_detail_screen.dart';
import '../services/wp_api_service.dart';
import '../utils/html_utils.dart';
import 'network_image_with_fallback.dart';

class ArticleList extends StatelessWidget {
  final String categoryName;

  const ArticleList(
      {super.key, required this.categoryName, required List<Article> articles});

  @override
  Widget build(BuildContext context) {
    final articleProvider = Provider.of<ArticleProvider>(context);
    final savedArticlesProvider = Provider.of<SavedArticlesProvider>(context);

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: articleProvider.articles.length,
            itemBuilder: (context, index) {
              Article article = articleProvider.articles[index];
              String formattedDate =
                  '⏰ ${DateFormat('MMMM d, y').format(DateTime.parse(article.date))}';

              return Card(
                margin: const EdgeInsets.all(10),
                child: InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ArticleDetailScreen(
                          article: article, categoryName: categoryName),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FutureBuilder<String>(
                          future: fetchFeaturedMedia(article.featured_media),
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
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(article.title,
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Text(formattedDate),
                                  const SizedBox(width: 10),
                                  FutureBuilder<String>(
                                    future: fetchAuthorName(article.author),
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
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, size: 32),
                  onPressed: articleProvider.currentPage > 1
                      ? () => articleProvider.previousPage()
                      : null,
                ),
                Text(
                  'Page ${articleProvider.currentPage} of ${articleProvider.totalPages}',
                  style: const TextStyle(fontSize: 16),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios, size: 32),
                  onPressed:
                      articleProvider.currentPage < articleProvider.totalPages
                          ? () => articleProvider.nextPage()
                          : null,
                ),
              ],
            ),
          ),
        ),
      ],
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
