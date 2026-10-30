import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/app_config.dart';
import '../screens/about_screen.dart';
import '../screens/contact_screen.dart';
import '../screens/deep_link_article_screen.dart';
import '../screens/saved_articles_screen.dart';

class DeepLinkHandler {
  static bool isInternalWebsiteHost(String host) {
    final normalized = host.trim().toLowerCase();
    final configured = AppConfig.instance.websiteDomain.toLowerCase();
    return normalized == configured ||
        normalized == 'www.$configured' ||
        normalized == 'thecollegeview.ie' ||
        normalized == 'www.thecollegeview.ie';
  }

  static bool isPrivacyPolicyPath(Uri uri) {
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.isEmpty) return false;
    final privacyUri = Uri.tryParse(AppConfig.instance.privacyPolicyUrl);
    final privacySlug = privacyUri?.pathSegments
        .where((s) => s.isNotEmpty)
        .lastOrNull
        ?.toLowerCase();
    final last = segments.last.toLowerCase();
    return (privacySlug != null && last == privacySlug) ||
        last.contains('the-college-view-mobile-app-privacy-policy');
  }

  /// Resolves an internal path or URL to a destination screen widget, or
  /// returns `null` if it should not be routed internally.
  static Widget? resolveDestinationWidget(
    String rawUrlOrPath, {
    bool requireInternalHost = false,
    bool allowSavedRoute = false,
  }) {
    final trimmed = rawUrlOrPath.trim();
    if (trimmed.isEmpty || trimmed == '/') return null;

    final uri = Uri.tryParse(trimmed);
    if (uri == null) return null;

    if (requireInternalHost || (uri.hasScheme && uri.host.isNotEmpty)) {
      if (!isInternalWebsiteHost(uri.host) || isPrivacyPolicyPath(uri)) {
        return null;
      }
    }

    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.length == 1) {
      switch (segments.first.toLowerCase()) {
        case 'about':
          return const AboutScreen();
        case 'contact':
          return const ContactScreen();
        case 'saved':
          if (allowSavedRoute) return const SavedArticlesScreen();
      }
    }

    if (segments.isNotEmpty || uri.queryParameters.containsKey('p')) {
      return DeepLinkArticleScreen(urlOrPath: trimmed);
    }

    return null;
  }

  /// Launches an external URL in the system browser.
  static Future<bool> launchExternalUrl(
    String rawUrl, {
    BuildContext? context,
    bool showErrorSnackBar = false,
  }) async {
    var normalizedUrl = rawUrl.trim();
    if (normalizedUrl.startsWith('http://')) {
      normalizedUrl = 'https://${normalizedUrl.substring(7)}';
    }
    final uri = Uri.tryParse(normalizedUrl);
    if (uri != null) {
      try {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          return true;
        }
      } catch (_) {}
    }

    if (showErrorSnackBar && context != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open link: $rawUrl')),
      );
    }
    return false;
  }

  /// Handles tapped URLs in HTML content: routes internal The College View
  /// links natively inside the app and launches external links in the browser.
  static Future<bool> handleTappedUrl(
    BuildContext context,
    String rawUrl,
  ) async {
    final destination = resolveDestinationWidget(
      rawUrl,
      requireInternalHost: true,
    );
    if (destination != null) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => destination),
      );
      return true;
    }

    return launchExternalUrl(rawUrl, context: context);
  }
}
