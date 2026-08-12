import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../screens/articles_screen.dart';
import '../screens/saved_articles_screen.dart';
import '../screens/about_screen.dart';
import '../screens/contact_screen.dart';
import '../providers/article_provider.dart';
import '../models/category.dart';
import 'social_media_icon.dart';

class CVNavigationDrawer extends StatelessWidget {
  const CVNavigationDrawer({super.key});


  @override
  Widget build(BuildContext context) {
    final articleProvider = Provider.of<ArticleProvider>(context);

    return Drawer(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                DrawerHeader(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Center(
                        child: Image.asset(
                          'assets/logo.png',
                          height: 135,
                          width: 300,
                        ),
                      ),
                    ],
                  ),
                ),

                ListTile(
                  title: const Text('All Articles'),
                  onTap: () {
                    articleProvider.clearFilters();
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const ArticlesScreen(categoryName: "All Articles"),
                      ),
                    );
                  },
                ),

                ListTile(
                  title: const Text('Saved Articles'),
                  leading: const Icon(Icons.bookmark),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SavedArticlesScreen(),
                      ),
                    );
                  },
                ),

                ...articleProvider.categories.map((category) {
                  return _buildCategoryTile(context, category);
                }),

                ListTile(
                  title: const Text('About'),
                  leading: const Icon(Icons.info),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AboutScreen(),
                      ),
                    );
                  },
                ),

                ListTile(
                  title: const Text('Contact'),
                  leading: const Icon(Icons.contact_mail),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ContactScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Always stays at the bottom
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SocialMediaIcon(
                  icon: FontAwesomeIcons.instagram,
                  url: 'https://instagram.com/thecollegeview',
                ),
                SizedBox(width: 10),
                SocialMediaIcon(
                  icon: FontAwesomeIcons.whatsapp,
                  url: 'https://chat.whatsapp.com/C8Rwkvo7h7k4STz79ICfHV',
                ),
                SizedBox(width: 10),
                SocialMediaIcon(
                  icon: FontAwesomeIcons.globe,
                  url: 'https://thecollegeview.ie',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTile(BuildContext context, Category category) {
    final articleProvider =
        Provider.of<ArticleProvider>(context, listen: false);

    if (category.subcategories.isEmpty) {
      return ListTile(
        contentPadding: const EdgeInsets.only(left: 16, right: 16),
        title: Text(category.name),
        onTap: () {
          articleProvider.selectCategory(category.id);
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ArticlesScreen(categoryName: category.name),
            ),
          );
        },
      );
    }

    return ExpansionTile(
      title: Text(category.name),
      tilePadding: const EdgeInsets.only(left: 16, right: 16),
      childrenPadding: const EdgeInsets.only(left: 16),
      children: [
        ListTile(
          contentPadding: const EdgeInsets.only(left: 16, right: 16),
          title: Text('All ${category.name}'),
          onTap: () {
            articleProvider.selectCategory(category.id);
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ArticlesScreen(
                  categoryName: 'All ${category.name}',
                ),
              ),
            );
          },
        ),

        ...category.subcategories.map((subCategory) {
          return Padding(
            padding: const EdgeInsets.only(left: 16),
            child: _buildCategoryTile(context, subCategory),
          );
        }),
      ],
    );
  }
}
