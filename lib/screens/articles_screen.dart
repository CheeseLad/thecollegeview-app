import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thecollegeview/screens/search_page.dart';
import '../widgets/cv_navigation_drawer.dart';
import '../widgets/article_list.dart';
import '../widgets/offline_banner.dart';
import '../providers/article_provider.dart';

class ArticlesScreen extends StatelessWidget {
  final String categoryName;

  const ArticlesScreen({super.key, required this.categoryName});

  @override
  Widget build(BuildContext context) {
    final articleProvider =
        Provider.of<ArticleProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(categoryName),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4.0),
            child: IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SearchPage()),
                );
              },
            ),
          ),
        ],
      ),
      drawer: const CVNavigationDrawer(),
      body: Column(
        children: [
          OfflineBanner(
            onRetry: () {
              articleProvider.refreshArticles();
            },
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await articleProvider.refreshArticles();
              },
              child: ArticleList(
                categoryName: categoryName,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
