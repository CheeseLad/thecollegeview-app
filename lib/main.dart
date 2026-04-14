import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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
  if (_hasRequiredFirebaseEnv()) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (e) {
      print('Firebase initialization error: $e');
      print('Note: Make sure you have added google-services.json (Android), GoogleService-Info.plist (iOS), and web config');
    }
  } else {
    print('Firebase initialization skipped: required FIREBASE_* environment variables are missing for this platform.');
  }
  
  runApp(const MyApp());
}

bool _hasRequiredFirebaseEnv() {
  final keys = kIsWeb
      ? const [
          'FIREBASE_WEB_API_KEY',
          'FIREBASE_WEB_APP_ID',
          'FIREBASE_WEB_MESSAGING_SENDER_ID',
          'FIREBASE_WEB_PROJECT_ID',
          'FIREBASE_WEB_AUTH_DOMAIN',
          'FIREBASE_WEB_STORAGE_BUCKET',
        ]
      : switch (defaultTargetPlatform) {
          TargetPlatform.android => const [
              'FIREBASE_ANDROID_API_KEY',
              'FIREBASE_ANDROID_APP_ID',
              'FIREBASE_ANDROID_MESSAGING_SENDER_ID',
              'FIREBASE_ANDROID_PROJECT_ID',
              'FIREBASE_ANDROID_STORAGE_BUCKET',
            ],
          TargetPlatform.iOS => const [
              'FIREBASE_IOS_API_KEY',
              'FIREBASE_IOS_APP_ID',
              'FIREBASE_IOS_MESSAGING_SENDER_ID',
              'FIREBASE_IOS_PROJECT_ID',
              'FIREBASE_IOS_STORAGE_BUCKET',
              'FIREBASE_IOS_BUNDLE_ID',
            ],
          TargetPlatform.macOS => const [
              'FIREBASE_MACOS_API_KEY',
              'FIREBASE_MACOS_APP_ID',
              'FIREBASE_MACOS_MESSAGING_SENDER_ID',
              'FIREBASE_MACOS_PROJECT_ID',
              'FIREBASE_MACOS_STORAGE_BUCKET',
              'FIREBASE_MACOS_BUNDLE_ID',
            ],
          TargetPlatform.windows => const [
              'FIREBASE_WINDOWS_API_KEY',
              'FIREBASE_WINDOWS_APP_ID',
              'FIREBASE_WINDOWS_MESSAGING_SENDER_ID',
              'FIREBASE_WINDOWS_PROJECT_ID',
              'FIREBASE_WINDOWS_AUTH_DOMAIN',
              'FIREBASE_WINDOWS_STORAGE_BUCKET',
            ],
          _ => const <String>[],
        };

  for (final key in keys) {
    final value = dotenv.env[key];
    if (value == null || value.isEmpty) {
      return false;
    }
  }
  return true;
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
