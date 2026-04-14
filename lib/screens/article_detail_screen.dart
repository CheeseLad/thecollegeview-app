import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/article.dart';
import '../models/tag.dart';
import '../providers/saved_articles_provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:convert';
import '../services/wp_api_service.dart';
import '../utils/html_utils.dart';
import '../widgets/network_image_with_fallback.dart';
import 'tag_articles_screen.dart';

class ArticleDetailScreen extends StatelessWidget {
  final Article article;

  final String categoryName;

  const ArticleDetailScreen(
      {super.key, required this.article, required this.categoryName});

  @override
  Widget build(BuildContext context) {
    String formattedDate =
        '⏰ ${DateFormat('MMMM d, y').format(DateTime.parse(article.date))}';
    final savedArticlesProvider = Provider.of<SavedArticlesProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(article.title),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4.0),
            child: IconButton(
              icon: Icon(
                savedArticlesProvider.isArticleSaved(article.id)
                    ? Icons.bookmark
                    : Icons.bookmark_border,
                color: savedArticlesProvider.isArticleSaved(article.id)
                    ? Colors.blue
                    : Colors.black87,
              ),
              onPressed: () {
                savedArticlesProvider.toggleSaveArticle(article, categoryName);
              },
            ),
          ),
        ],
      ),
      body: Container(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Text(
                article.title,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(formattedDate),
                  const SizedBox(width: 10),
                  FutureBuilder<String>(
                    future: fetchAuthorName(article.author),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      } else if (snapshot.hasError) {
                        return const Text('Error');
                      } else {
                        // Check if categoryName is a tag (starts with "Tag: ")
                        final isTag = categoryName.startsWith('Tag: ');
                        final authorText = isTag 
                            ? 'by ${snapshot.data}'
                            : 'by ${snapshot.data} in $categoryName';
                        return Text(authorText,
                            style: TextStyle(
                                fontSize: 16, color: Colors.grey[600]));
                      }
                    },
                  ),
                ],
              ),
              // Show tag on a new line if viewing tagged articles
              if (categoryName.startsWith('Tag: ')) ...[
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Text('🏷️ '),
                    Text(
                      () {
                        final tagName = categoryName.substring(5);
                        return tagName.isEmpty
                            ? tagName
                            : tagName[0].toUpperCase() + tagName.substring(1);
                      }(),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 10),
              // Display featured media if available
              if (article.featured_media > 0)
                FutureBuilder<String>(
                  future: fetchFeaturedMedia(article.featured_media),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Container(
                        width: double.infinity,
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      );
                    } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        child: NetworkImageWithFallback(
                          imageUrl: snapshot.data!,
                          fallbackAssetPath: 'assets/logo.png',
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      );
                    } else {
                      return const SizedBox.shrink();
                    }
                  },
                ),
              HtmlWidget(
                article.content,
                renderMode: RenderMode.column,
                textStyle: const TextStyle(fontSize: 16),
                customStylesBuilder: (element) {
                  if (element.localName == 'img') {
                    return {
                      'border-radius': '10px',
                    };
                  }
                  return null;
                },
                customWidgetBuilder: (element) {
                  if (element.localName == 'img') {
                    final src = element.attributes['src'];
                    if (src != null && src.isNotEmpty) {
                      return NetworkImageWithFallback(
                        imageUrl: src,
                        fallbackAssetPath: 'assets/logo.png',
                        borderRadius: BorderRadius.circular(10),
                      );
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              // Display tags if available
              if (article.tags.isNotEmpty) ...[
                // Text('Debug: Article has ${article.tags.length} tags: ${article.tags}'), // Debug
                FutureBuilder<List<String>>(
                  future: fetchTags(article.tags),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox.shrink();
                    } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            //const Text(
                            //  'Tags:',
                            //  style: TextStyle(
                            //    fontSize: 16,
                            //    fontWeight: FontWeight.bold,
                            //    color: Colors.grey,
                            //  ),
                            //),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8.0,
                              runSpacing: 4.0,
                              children: snapshot.data!.asMap().entries.map((entry) {
                                final index = entry.key;
                                final tagName = entry.value;
                                final tagId = article.tags[index];
                                
                                return GestureDetector(
                                  onTap: () async {
                                    // Create a Tag object for navigation
                                    final tag = Tag(
                                      id: tagId,
                                      name: tagName,
                                      slug: tagName.toLowerCase().replaceAll(' ', '-'),
                                      description: '',
                                      count: 0,
                                    );
                                    
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => TagArticlesScreen(tag: tag),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade100,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: Colors.blue.shade300,
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          tagName,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.blue.shade800,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Icon(
                                          Icons.arrow_forward_ios,
                                          size: 12,
                                          color: Colors.blue.shade800,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      );
                    } else {
                      return const SizedBox.shrink();
                    }
                  },
                ),
              ] else ...[
                const Text('Debug: Article has no tags'), // Debug
              ],
              GestureDetector(
                onTap: () {
                  Share.share(article.link);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black, width: 1.0),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.share),
                      SizedBox(width: 8.0),
                      Text(
                        "Share",
                        style: TextStyle(fontSize: 18.0),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
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

  Future<List<String>> fetchTags(List<int> tagIds) async {
    if (tagIds.isEmpty) return [];
    
    try {
      final List<String> tagNames = [];
      
      for (int tagId in tagIds) {
        final response = await WpApiService.get(
            Uri.parse('https://thecollegeview.ie/wp-json/wp/v2/tags/$tagId'));
        
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          tagNames.add(HtmlUtils.decodeHtmlEntities(data['name']));
        }
      }
      
      return tagNames;
    } catch (e) {
      return [];
    }
  }

}
