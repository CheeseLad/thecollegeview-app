import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/saved_articles_provider.dart';
import '../widgets/article_list.dart';
import '../widgets/cv_navigation_drawer.dart';

class SavedArticlesScreen extends StatelessWidget {
  const SavedArticlesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final savedArticlesProvider = Provider.of<SavedArticlesProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Articles'),
      ),
      drawer: const CVNavigationDrawer(),
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
                  final savedArticle =
                      savedArticlesProvider.savedArticles[index];

                  return ArticleCard(
                    key: ValueKey(savedArticle.id),
                    article: savedArticle.article,
                    categoryName: savedArticle.categoryName,
                    savedAt: savedArticle.savedAt,
                    tagNames: savedArticle.tagNames,
                    onRemove: () =>
                        savedArticlesProvider.removeArticle(savedArticle.id),
                  );
                },
              ),
      ),
    );
  }
}
