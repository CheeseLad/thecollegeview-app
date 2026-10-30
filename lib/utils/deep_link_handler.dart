import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/app_urls.dart';
import '../screens/about_screen.dart';
import '../screens/contact_screen.dart';
import '../screens/deep_link_article_screen.dart';

class DeepLinkHandler {
  static bool isInternalWebsiteHost(String host) {
    final normalized = host.trim().toLowerCase();
    final configured = AppUrls.websiteDomain.toLowerCase();
    return normalized == configured ||
        normalized == 'www.$configured' ||
        normalized == 'thecollegeview.ie' ||
        normalized == 'www.thecollegeview.ie';
  }

  static bool isPrivacyPolicyPath(Uri uri) {
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.isEmpty) return false;
    return segments.last
        .toLowerCase()
        .contains('the-college-view-mobile-app-privacy-policy');
  }

  /// Handles tapped URLs in HTML content: routes internal The College View
  /// article links natively inside the app and launches external links in the
  /// system browser.
  static Future<bool> handleTappedUrl(
    BuildContext context,
    String rawUrl,
  ) async {
    final uri = Uri.tryParse(rawUrl.trim());
    if (uri == null) return false;

    if (isInternalWebsiteHost(uri.host) && !isPrivacyPolicyPath(uri)) {
      final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
      if (segments.length == 1) {
        final slug = segments.first.toLowerCase();
        if (slug == 'about') {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AboutScreen()),
          );
          return true;
        }
        if (slug == 'contact') {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ContactScreen()),
          );
          return true;
        }
      }

      if (segments.isNotEmpty || uri.queryParameters.containsKey('p')) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DeepLinkArticleScreen(urlOrPath: rawUrl),
          ),
        );
        return true;
      }
    }

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return true;
    }
    return false;
  }
}

