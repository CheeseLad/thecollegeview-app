import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'config/app_config.dart';
import 'theme/app_theme.dart';
import 'services/cache_service.dart';
import 'providers/article_provider.dart';
import 'providers/saved_articles_provider.dart';
import 'screens/articles_screen.dart';
import 'screens/article_detail_screen.dart';
import 'utils/deep_link_handler.dart';
import 'utils/display_utils.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  await Future.wait([
    DisplayUtils.enableHighRefreshRate(),
    AppConfig.load(),
    Hive.initFlutter(),
  ]);

  final savedArticlesProvider = SavedArticlesProvider();
  final themeProvider = ThemeProvider();
  await Future.wait([
    CacheService().init(),
    savedArticlesProvider.init(),
    themeProvider.init(),
  ]);

  runApp(MyApp(
    savedArticlesProvider: savedArticlesProvider,
    themeProvider: themeProvider,
  ));
}

class MyApp extends StatefulWidget {
  final SavedArticlesProvider savedArticlesProvider;
  final ThemeProvider themeProvider;

  const MyApp({
    super.key,
    required this.savedArticlesProvider,
    required this.themeProvider,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      DisplayUtils.enableHighRefreshRate();
    }
  }

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
        ChangeNotifierProvider.value(value: widget.savedArticlesProvider),
        ChangeNotifierProvider.value(value: widget.themeProvider),
      ],
      child: Selector<ThemeProvider, ThemeMode>(
        selector: (_, themeProvider) => themeProvider.themeMode,
        builder: (context, themeMode, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: AppConfig.instance.appName,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeMode,
            builder: (context, appChild) {
              return AnnotatedRegion<SystemUiOverlayStyle>(
                value: AppTheme.systemOverlayStyleFor(context),
                child: appChild ?? const SizedBox.shrink(),
              );
            },
            home: const ArticlesScreen(categoryName: 'All Articles'),
            onGenerateRoute: _onGenerateRoute,
          );
        },
      ),
    );
  }
}
