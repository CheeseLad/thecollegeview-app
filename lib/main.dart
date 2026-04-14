import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'providers/article_provider.dart';
import 'providers/saved_articles_provider.dart';
import 'providers/page_content_provider.dart';
import 'screens/articles_screen.dart';
import 'screens/article_detail_screen.dart';
// import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    print('Warning: Could not load .env file: $e');
    print('Using default values from firebase_options.dart');
  }
  
  await Hive.initFlutter();
  
  // Initialize Firebase with platform-specific options
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print('Firebase initialization error: $e');
    print('Note: Make sure you have added google-services.json (Android), GoogleService-Info.plist (iOS), and web config');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  late final ArticleProvider _articleProvider;

  @override
  void initState() {
    super.initState();
    _articleProvider = ArticleProvider();
    // Push notifications are temporarily disabled.
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   NotificationService().initialize(_navigatorKey, _articleProvider);
    // });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _articleProvider),
        ChangeNotifierProvider(create: (context) => SavedArticlesProvider()),
        ChangeNotifierProvider(create: (context) => PageContentProvider()),
      ],
      child: MaterialApp(
        navigatorKey: _navigatorKey,
        debugShowCheckedModeBanner: false,
        title: 'The College View',
        theme: ThemeData(
          scaffoldBackgroundColor: Colors.grey[400],
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            background: Colors.grey[400]!,
          ),
        ),
        home: const ArticlesScreen(categoryName: "All Articles"),
        routes: {
          '/article': (context) {
            final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
            return ArticleDetailScreen(
              article: args['article'],
              categoryName: args['categoryName'] ?? 'All Articles',
            );
          },
        },
      ),
    );
  }
}
