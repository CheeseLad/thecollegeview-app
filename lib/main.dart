import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'theme/app_theme.dart';
import 'services/cache_service.dart';
import 'providers/article_provider.dart';
import 'providers/saved_articles_provider.dart';
import 'providers/page_content_provider.dart';
import 'screens/articles_screen.dart';
import 'screens/article_detail_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
            title: 'The College View',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const ArticlesScreen(categoryName: "All Articles"),
            routes: {
              '/article': (context) {
                final args = ModalRoute.of(context)!.settings.arguments
                    as Map<String, dynamic>;
                return ArticleDetailScreen(
                  article: args['article'],
                  categoryName: args['categoryName'] ?? 'All Articles',
                  authorName: args['authorName'],
                  featuredMediaUrl: args['featuredMediaUrl'],
                  tagNames: args['tagNames'],
                );
              },
            },
          );
        },
      ),
    );
  }
}
