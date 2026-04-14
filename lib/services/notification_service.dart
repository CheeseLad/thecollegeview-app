/*
import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../providers/article_provider.dart';

// Top-level function to handle background messages
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling background message: ${message.messageId}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  StreamSubscription<RemoteMessage>? _messageSubscription;
  GlobalKey<NavigatorState>? _navigatorKey;
  ArticleProvider? _articleProvider;

  // Initialize notification service
  Future<void> initialize(GlobalKey<NavigatorState> navigatorKey, ArticleProvider articleProvider) async {
    _navigatorKey = navigatorKey;
    _articleProvider = articleProvider;

    // Request permission for notifications
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted notification permission');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      print('User granted provisional notification permission');
    } else {
      print('User declined or has not accepted notification permission');
    }

    // Initialize local notifications for Android
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channel for Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'article_notifications',
      'Article Notifications',
      description: 'Notifications for new articles',
      importance: Importance.high,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Set up background message handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    _messageSubscription = FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification taps when app is in background/terminated
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Check if app was opened from a notification
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }

    // Get FCM token
    String? token = await _firebaseMessaging.getToken();
    print('FCM Token: $token');

    // Subscribe to topic for all users to receive article notifications
    // Note: Topic subscription is not supported on web, so we skip it for web platforms
    if (!kIsWeb) {
      try {
        await _firebaseMessaging.subscribeToTopic('new_articles');
        print('Subscribed to topic: new_articles');
      } catch (e) {
        print('Error subscribing to topic: $e');
      }
    } else {
      print('Topic subscription skipped on web (not supported). Use FCM token directly for web notifications.');
    }

    // Token refresh listener
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      print('FCM Token refreshed: $newToken');
    });
  }

  // Handle foreground messages
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('Received foreground message: ${message.messageId}');
    print('Message data: ${message.data}');
    print('Notification: ${message.notification?.title} - ${message.notification?.body}');

    final notification = message.notification;

    if (notification != null) {
      if (kIsWeb) {
        // On web, notifications are handled by the service worker
        // The browser will show them automatically
        print('Foreground notification received on web - browser will handle display');
      } else {
        // Show local notification when app is in foreground (mobile only)
        await _localNotifications.show(
          notification.hashCode,
          notification.title ?? 'New Article',
          notification.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'article_notifications',
              'Article Notifications',
              channelDescription: 'Notifications for new articles',
              importance: Importance.high,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
            ),
            iOS: DarwinNotificationDetails(),
          ),
          payload: message.data['article_id']?.toString(),
        );
      }
    }
  }

  // Handle notification tap
  Future<void> _handleNotificationTap(RemoteMessage message) async {
    print('Notification tapped: ${message.messageId}');

    final articleId = message.data['article_id'];
    if (articleId != null && _navigatorKey?.currentContext != null && _articleProvider != null) {
      await _navigateToArticle(int.parse(articleId.toString()));
    }
  }

  // Handle local notification tap
  void _onNotificationTapped(NotificationResponse response) {
    print('Local notification tapped: ${response.payload}');

    if (response.payload != null && _navigatorKey?.currentContext != null && _articleProvider != null) {
      final articleId = int.tryParse(response.payload!);
      if (articleId != null) {
        _navigateToArticle(articleId);
      }
    }
  }

  // Navigate to article
  Future<void> _navigateToArticle(int articleId) async {
    if (_navigatorKey?.currentContext == null || _articleProvider == null) return;

    try {
      final article = await _articleProvider!.fetchArticleById(articleId);
      if (article != null && _navigatorKey?.currentContext != null) {
        Navigator.of(_navigatorKey!.currentContext!).pushNamed(
          '/article',
          arguments: {'article': article, 'categoryName': 'All Articles'},
        );
      }
    } catch (e) {
      print('Error navigating to article: $e');
    }
  }

  // Dispose resources
  void dispose() {
    _messageSubscription?.cancel();
    _navigatorKey = null;
    _articleProvider = null;
  }

  // Get FCM token (useful for backend registration)
  Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }
}
*/

