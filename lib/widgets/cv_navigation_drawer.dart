import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../screens/articles_screen.dart';
import '../screens/saved_articles_screen.dart';
import '../screens/about_screen.dart';
import '../screens/contact_screen.dart';
import '../providers/article_provider.dart';
import '../models/category.dart';
import '../config/app_config.dart';
import '../theme/app_theme.dart';
import '../utils/deep_link_handler.dart';
import 'social_media_icon.dart';

class CVNavigationDrawer extends StatelessWidget {
  const CVNavigationDrawer({super.key});

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.pop(context);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final articleProvider = Provider.of<ArticleProvider>(context);
    final config = AppConfig.instance;

    return Drawer(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                DrawerHeader(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Center(
                    child: Image.asset(
                      'assets/logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.newspaper),
                  title: const Text('All Articles'),
                  onTap: () {
                    articleProvider.clearFilters();
                    _navigateTo(
                      context,
                      const ArticlesScreen(categoryName: 'All Articles'),
                    );
                  },
                ),
                ListTile(
                  title: const Text('Saved Articles'),
                  leading: const Icon(Icons.bookmark),
                  onTap: () {
                    _navigateTo(context, const SavedArticlesScreen());
                  },
                ),
                ...articleProvider.categories.map((category) {
                  return _buildCategoryTile(context, category);
                }),
                const Divider(),
                ListTile(
                  title: const Text('About'),
                  leading: const Icon(Icons.info_outline),
                  onTap: () {
                    _navigateTo(context, const AboutScreen());
                  },
                ),
                ListTile(
                  title: const Text('Contact'),
                  leading: const Icon(Icons.contact_mail_outlined),
                  onTap: () {
                    _navigateTo(context, const ContactScreen());
                  },
                ),
                ListTile(
                  title: const Text('Privacy Policy'),
                  leading: const Icon(Icons.privacy_tip_outlined),
                  onTap: () {
                    Navigator.pop(context);
                    DeepLinkHandler.launchExternalUrl(config.privacyPolicyUrl);
                  },
                ),
                Consumer<ThemeProvider>(
                  builder: (context, themeProvider, child) {
                    final (icon, label) = switch (themeProvider.themeMode) {
                      ThemeMode.system => (
                          Icons.brightness_auto,
                          'Theme: System'
                        ),
                      ThemeMode.light => (Icons.light_mode, 'Theme: Light'),
                      ThemeMode.dark => (Icons.dark_mode, 'Theme: Dark'),
                    };

                    return ListTile(
                      title: Text(label),
                      subtitle: const Text('Tap to cycle theme'),
                      leading: Icon(icon),
                      onTap: themeProvider.cycleThemeMode,
                    );
                  },
                ),
              ],
            ),
          ),

          // Always stays at the bottom
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SocialMediaIcon(
                  icon: FontAwesomeIcons.instagram,
                  url: config.instagramUrl,
                ),
                const SizedBox(width: 10),
                SocialMediaIcon(
                  icon: FontAwesomeIcons.whatsapp,
                  url: config.whatsappUrl,
                ),
                const SizedBox(width: 10),
                SocialMediaIcon(
                  icon: FontAwesomeIcons.globe,
                  url: config.website,
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
          _navigateTo(
            context,
            ArticlesScreen(categoryName: category.name),
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
            _navigateTo(
              context,
              ArticlesScreen(
                categoryName: 'All ${category.name}',
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
