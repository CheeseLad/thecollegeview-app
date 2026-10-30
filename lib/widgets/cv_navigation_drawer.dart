import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../screens/articles_screen.dart';
import '../screens/saved_articles_screen.dart';
import '../screens/about_screen.dart';
import '../screens/contact_screen.dart';
import '../providers/article_provider.dart';
import '../providers/saved_articles_provider.dart';
import '../models/category.dart';
import '../config/app_config.dart';
import '../theme/app_theme.dart';
import '../utils/deep_link_handler.dart';

enum _DrawerDestination {
  articles,
  saved,
  about,
  contact,
}

class CVNavigationDrawer extends StatelessWidget {
  const CVNavigationDrawer({super.key});

  _DrawerDestination _resolveActiveDestination(BuildContext context) {
    if (context.findAncestorWidgetOfExactType<SavedArticlesScreen>() != null) {
      return _DrawerDestination.saved;
    }
    if (context.findAncestorWidgetOfExactType<AboutScreen>() != null) {
      return _DrawerDestination.about;
    }
    if (context.findAncestorWidgetOfExactType<ContactScreen>() != null) {
      return _DrawerDestination.contact;
    }
    return _DrawerDestination.articles;
  }

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.pop(context);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  Widget _buildStyledTile(
    BuildContext context, {
    required String title,
    IconData? icon,
    Widget? subtitle,
    Widget? trailing,
    bool selected = false,
    EdgeInsetsGeometry contentPadding =
        const EdgeInsets.symmetric(horizontal: 14),
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: ListTile(
        dense: true,
        visualDensity: const VisualDensity(vertical: -0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: contentPadding,
        selected: selected,
        selectedTileColor: colorScheme.primaryContainer.withValues(alpha: 0.65),
        selectedColor: colorScheme.primary,
        leading: icon != null ? Icon(icon, size: 22) : null,
        title: Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        subtitle: subtitle,
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }

  Widget _buildSectionLabel(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 16, 4),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final articleProvider = Provider.of<ArticleProvider>(context);
    final config = AppConfig.instance;
    final activeDestination = _resolveActiveDestination(context);
    final selectedCategoryId = articleProvider.selectedCategory;
    final isAllArticlesSelected =
        activeDestination == _DrawerDestination.articles &&
            selectedCategoryId == null;
    final isSavedSelected = activeDestination == _DrawerDestination.saved;
    final isAboutSelected = activeDestination == _DrawerDestination.about;
    final isContactSelected = activeDestination == _DrawerDestination.contact;

    return Drawer(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                DrawerHeader(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Center(
                    child: Image.asset(
                      'assets/logo.png',
                      fit: BoxFit.contain,
                      cacheWidth: (260 *
                              MediaQuery.devicePixelRatioOf(context)
                                  .clamp(1.0, 3.5))
                          .round(),
                    ),
                  ),
                ),
                _buildStyledTile(
                  context,
                  icon: isAllArticlesSelected
                      ? Icons.newspaper
                      : Icons.newspaper_outlined,
                  title: 'All Articles',
                  selected: isAllArticlesSelected,
                  onTap: () {
                    if (isAllArticlesSelected) {
                      Navigator.pop(context);
                      return;
                    }
                    articleProvider.clearFilters();
                    _navigateTo(
                      context,
                      const ArticlesScreen(categoryName: 'All Articles'),
                    );
                  },
                ),
                Selector<SavedArticlesProvider, int>(
                  selector: (_, p) => p.savedArticles.length,
                  builder: (context, savedCount, _) {
                    final colorScheme = Theme.of(context).colorScheme;
                    return _buildStyledTile(
                      context,
                      icon: isSavedSelected
                          ? Icons.bookmark
                          : Icons.bookmark_border,
                      title: 'Saved Articles',
                      selected: isSavedSelected,
                      trailing: savedCount > 0
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isSavedSelected
                                    ? colorScheme.primary
                                    : colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$savedCount',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isSavedSelected
                                      ? colorScheme.onPrimary
                                      : colorScheme.onSurfaceVariant,
                                ),
                              ),
                            )
                          : null,
                      onTap: () {
                        if (isSavedSelected) {
                          Navigator.pop(context);
                          return;
                        }
                        _navigateTo(context, const SavedArticlesScreen());
                      },
                    );
                  },
                ),
                if (articleProvider.categories.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Divider(height: 1),
                  ),
                  _buildSectionLabel(context, 'Sections'),
                  ...articleProvider.categories.map((category) {
                    return _buildCategoryTile(
                      context,
                      category,
                      activeDestination: activeDestination,
                      selectedCategoryId: selectedCategoryId,
                    );
                  }),
                ],
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Divider(height: 1),
                ),
                _buildSectionLabel(context, 'More'),
                _buildStyledTile(
                  context,
                  title: 'About',
                  icon: isAboutSelected ? Icons.info : Icons.info_outline,
                  selected: isAboutSelected,
                  onTap: () {
                    if (isAboutSelected) {
                      Navigator.pop(context);
                      return;
                    }
                    _navigateTo(context, const AboutScreen());
                  },
                ),
                _buildStyledTile(
                  context,
                  title: 'Contact',
                  icon: isContactSelected
                      ? Icons.contact_mail
                      : Icons.contact_mail_outlined,
                  selected: isContactSelected,
                  onTap: () {
                    if (isContactSelected) {
                      Navigator.pop(context);
                      return;
                    }
                    _navigateTo(context, const ContactScreen());
                  },
                ),
                _buildStyledTile(
                  context,
                  title: 'Privacy Policy',
                  icon: Icons.privacy_tip_outlined,
                  trailing: Icon(
                    Icons.open_in_new,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
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

                    return _buildStyledTile(
                      context,
                      title: label,
                      subtitle: const Text(
                        'Tap to change theme',
                        style: TextStyle(fontSize: 12),
                      ),
                      icon: icon,
                      onTap: themeProvider.cycleThemeMode,
                    );
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),

          // Always stays at the bottom, respecting bottom gesture bar inset
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _SocialMediaIcon(
                    icon: FontAwesomeIcons.instagram,
                    url: config.instagramUrl,
                  ),
                  const SizedBox(width: 10),
                  _SocialMediaIcon(
                    icon: FontAwesomeIcons.whatsapp,
                    url: config.whatsappUrl,
                  ),
                  const SizedBox(width: 10),
                  _SocialMediaIcon(
                    icon: FontAwesomeIcons.globe,
                    url: config.website,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _containsSelectedCategory(Category category, int? selectedCategoryId) {
    if (selectedCategoryId == null) return false;
    if (category.id == selectedCategoryId) return true;
    for (final sub in category.subcategories) {
      if (_containsSelectedCategory(sub, selectedCategoryId)) {
        return true;
      }
    }
    return false;
  }

  Widget _buildCategoryTile(
    BuildContext context,
    Category category, {
    required _DrawerDestination activeDestination,
    required int? selectedCategoryId,
    bool isSubcategory = false,
  }) {
    final articleProvider =
        Provider.of<ArticleProvider>(context, listen: false);
    final isArticlesScreen = activeDestination == _DrawerDestination.articles;
    final isSelected = isArticlesScreen && selectedCategoryId == category.id;

    if (category.subcategories.isEmpty) {
      return _buildStyledTile(
        context,
        title: category.name,
        selected: isSelected,
        contentPadding: EdgeInsets.only(
          left: isSubcategory ? 26 : 14,
          right: 14,
        ),
        onTap: () {
          if (isSelected) {
            Navigator.pop(context);
            return;
          }
          articleProvider.selectCategory(category.id);
          _navigateTo(
            context,
            ArticlesScreen(categoryName: category.name),
          );
        },
      );
    }

    final hasActiveChild = isArticlesScreen &&
        _containsSelectedCategory(category, selectedCategoryId);
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: hasActiveChild,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          tilePadding: const EdgeInsets.symmetric(horizontal: 14),
          childrenPadding: const EdgeInsets.only(left: 8, bottom: 4),
          iconColor: hasActiveChild ? colorScheme.primary : null,
          collapsedIconColor: hasActiveChild ? colorScheme.primary : null,
          title: Text(
            category.name,
            style: TextStyle(
              fontSize: 15,
              fontWeight: hasActiveChild ? FontWeight.w700 : FontWeight.w500,
              color: hasActiveChild ? colorScheme.primary : null,
            ),
          ),
          children: [
            _buildStyledTile(
              context,
              title: 'All ${category.name}',
              selected: isSelected,
              contentPadding: const EdgeInsets.only(left: 26, right: 14),
              onTap: () {
                if (isSelected) {
                  Navigator.pop(context);
                  return;
                }
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
              return _buildCategoryTile(
                context,
                subCategory,
                activeDestination: activeDestination,
                selectedCategoryId: selectedCategoryId,
                isSubcategory: true,
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _SocialMediaIcon extends StatelessWidget {
  final FaIconData icon;
  final String url;

  const _SocialMediaIcon({required this.icon, required this.url});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => DeepLinkHandler.launchExternalUrl(
        url,
        context: context,
        showErrorSnackBar: true,
      ),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: FaIcon(icon, size: 28),
      ),
    );
  }
}
