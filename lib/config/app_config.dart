import 'dart:convert';
import 'package:flutter/services.dart';

class AppConfig {
  static const String defaultAppName = 'The College View';
  static const String defaultAppDescription =
      "The College View - DCU's Independent Student Newspaper";
  static const String defaultFallbackAuthorName = 'The College View';
  static const String defaultCopyrightNotice =
      '© The College View 1999-2026 - Maintained by Jake Farrell';
  static const String defaultApiBase = 'https://tcvappapi.jakefarrell.ie';
  static const String defaultWebsite = 'https://thecollegeview.ie';
  static const String defaultWebsiteDomain = 'thecollegeview.ie';
  static const String defaultInstagramUrl =
      'https://instagram.com/thecollegeview';
  static const String defaultWhatsappUrl =
      'https://chat.whatsapp.com/C8Rwkvo7h7k4STz79ICfHV';
  static const String defaultImageProxyUrl =
      'https://images.weserv.nl/?url=';

  final String appName;
  final String appDescription;
  final String fallbackAuthorName;
  final String copyrightNotice;
  final String apiBase;
  final String website;
  final String websiteDomain;
  final String instagramUrl;
  final String whatsappUrl;
  final String imageProxyUrl;

  const AppConfig({
    this.appName = defaultAppName,
    this.appDescription = defaultAppDescription,
    this.fallbackAuthorName = defaultFallbackAuthorName,
    this.copyrightNotice = defaultCopyrightNotice,
    this.apiBase = defaultApiBase,
    this.website = defaultWebsite,
    this.websiteDomain = defaultWebsiteDomain,
    this.instagramUrl = defaultInstagramUrl,
    this.whatsappUrl = defaultWhatsappUrl,
    this.imageProxyUrl = defaultImageProxyUrl,
  });

  static const AppConfig defaults = AppConfig();
  static AppConfig _instance = defaults;

  /// Global accessor for current application configuration.
  static AppConfig get instance => _instance;

  /// Override configuration instance (e.g. for testing or dynamic reload).
  static void setInstance(AppConfig config) {
    _instance = config;
  }

  /// Reset instance back to defaults.
  static void resetForTesting() {
    _instance = defaults;
  }

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    final urls = (json['urls'] as Map<String, dynamic>?) ?? {};

    final website = (json['website'] ?? urls['website'] ?? defaultWebsite)
        .toString()
        .trim();

    String parsedDomain = defaultWebsiteDomain;
    if (json['websiteDomain'] != null) {
      parsedDomain = json['websiteDomain'].toString().trim();
    } else if (urls['websiteDomain'] != null) {
      parsedDomain = urls['websiteDomain'].toString().trim();
    } else {
      final uri = Uri.tryParse(website);
      if (uri != null && uri.host.isNotEmpty) {
        parsedDomain = uri.host;
      }
    }

    return AppConfig(
      appName:
          (json['appName'] ?? json['name'] ?? defaultAppName).toString().trim(),
      appDescription: (json['appDescription'] ??
              json['description'] ??
              defaultAppDescription)
          .toString()
          .trim(),
      fallbackAuthorName: (json['fallbackAuthorName'] ??
              json['authorFallback'] ??
              defaultFallbackAuthorName)
          .toString()
          .trim(),
      copyrightNotice: (json['copyrightNotice'] ??
              json['copyright'] ??
              defaultCopyrightNotice)
          .toString()
          .trim(),
      apiBase: (json['apiBase'] ?? urls['apiBase'] ?? defaultApiBase)
          .toString()
          .trim(),
      website: website,
      websiteDomain: parsedDomain,
      instagramUrl: (json['instagramUrl'] ??
              urls['instagram'] ??
              urls['instagramUrl'] ??
              defaultInstagramUrl)
          .toString()
          .trim(),
      whatsappUrl: (json['whatsappUrl'] ??
              urls['whatsapp'] ??
              urls['whatsappUrl'] ??
              defaultWhatsappUrl)
          .toString()
          .trim(),
      imageProxyUrl: (json['imageProxyUrl'] ??
              urls['imageProxy'] ??
              urls['imageProxyUrl'] ??
              defaultImageProxyUrl)
          .toString()
          .trim(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'appName': appName,
      'appDescription': appDescription,
      'fallbackAuthorName': fallbackAuthorName,
      'copyrightNotice': copyrightNotice,
      'urls': {
        'apiBase': apiBase,
        'website': website,
        'websiteDomain': websiteDomain,
        'instagram': instagramUrl,
        'whatsapp': whatsappUrl,
        'imageProxy': imageProxyUrl,
      },
    };
  }

  static Future<AppConfig> load({
    String path = 'assets/config/app_config.json',
  }) async {
    try {
      final raw = await rootBundle.loadString(path);
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        final config = AppConfig.fromJson(decoded);
        _instance = config;
        return config;
      }
    } catch (_) {
      // Retain existing/default instance on failure.
    }
    return _instance;
  }
}

