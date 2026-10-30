import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'config/app_config.dart';
import 'theme/app_theme.dart';
import 'services/cache_service.dart';
import 'providers/article_provider.dart';
import 'providers/saved_articles_provider.dart';
import 'providers/page_content_provider.dart';
import 'screens/articles_screen.dart';
import 'screens/article_detail_screen.dart';
import 'utils/deep_link_handler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AppConfig.load();

  await Hive.initFlutter();
  await CacheService().init();

  final savedArticlesProvider = SavedArticlesProvider();
  await savedArticlesProvider.init();

  final themeProvider = ThemeProvider();
  await themeProvider.init();

  runApp(MyApp(
    savedArticlesProvider: savedArticlesProvider,
    themeProvider: themeProvider,
  ));
}

class MyApp extends StatelessWidget {
  final SavedArticlesProvider savedArticlesProvider;
  final ThemeProvider themeProvider;

  const MyApp({
    super.key,
    required this.savedArticlesProvider,
    required this.themeProvider,
  });

  Route<dynamic> _onGenerateRoute(RouteSettings settings) {
    final routeName = (settings.name ?? '/').trim();

    if (routeName == '/article' && settings.arguments is Map<String, dynamic>) {
      final args = settings.arguments as Map<String, dynamic>;
      return MaterialPageRoute(
        settings: settings,
        builder: (context) => ArticleDetailScreen(
          article: args['article'],
          categoryName: args['categoryName'] ?? 'All Articles',
          authorName: args['authorName'],
          featuredMediaUrl: args['featuredMediaUrl'],
          tagNames: args['tagNames'],
        ),
      );
    }

    final destination = DeepLinkHandler.resolveDestinationWidget(
      routeName,
      allowSavedRoute: true,
    );

    return MaterialPageRoute(
      settings: settings,
      builder: (context) =>
          destination ?? const ArticlesScreen(categoryName: 'All Articles'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ArticleProvider()),
        ChangeNotifierProvider.value(value: savedArticlesProvider),
        ChangeNotifierProvider(create: (context) => PageContentProvider()),
        ChangeNotifierProvider.value(value: themeProvider),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: AppConfig.instance.appName,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const ArticlesScreen(categoryName: 'All Articles'),
            onGenerateRoute: _onGenerateRoute,
          );
        },
      ),
    );
  }
}
