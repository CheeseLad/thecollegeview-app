import 'dart:convert';
import 'package:flutter/services.dart';

class ContactEntry {
  final String title;
  final List<String> emails;

  const ContactEntry({
    required this.title,
    required this.emails,
  });

  factory ContactEntry.fromJson(Map<String, dynamic> json) {
    final rawEmails = json['emails'];
    final emails = rawEmails is List
        ? rawEmails
            .map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList()
        : <String>[];
    return ContactEntry(
      title: (json['title'] ?? '').toString().trim(),
      emails: emails,
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'emails': emails,
      };
}

class AppConfig {
  static const String defaultAppName = 'The College View';
  static const String defaultAppDescription =
      "The College View - DCU's Independent Student Newspaper";
  static const String defaultFallbackAuthorName = 'The College View';
  static const bool defaultEnableAuthorTap = false;
  static const String defaultCopyrightNotice =
      '© The College View 1999-2026 - Maintained by Jake Farrell';
  static const String defaultApiBase = 'https://tcvappapi.jakefarrell.ie';
  static const String defaultWebsite = 'https://thecollegeview.ie';
  static const String defaultWebsiteDomain = 'thecollegeview.ie';
  static const String defaultPrivacyPolicyPath =
      '/the-college-view-mobile-app-privacy-policy';
  static const String defaultInstagramUrl =
      'https://instagram.com/thecollegeview';
  static const String defaultWhatsappUrl =
      'https://chat.whatsapp.com/C8Rwkvo7h7k4STz79ICfHV';
  static const String defaultImageProxyUrl = 'https://images.weserv.nl/?url=';

  static const List<ContactEntry> defaultContacts = [
    ContactEntry(
      title: "Editor-in-Chief: Katie O'Shaughnessy",
      emails: ['editor@thecollegeview.ie'],
    ),
    ContactEntry(
      title: 'Deputy Chief Editor: Leonor Selas Amaral',
      emails: ['deputyeditor@thecollegeview.ie'],
    ),
    ContactEntry(
      title: 'News: Annu Mandal & Adam Van Eekeren',
      emails: ['news@thecollegeview.ie'],
    ),
    ContactEntry(
      title: 'Opinions & Features: Ciara McGuinness, Erin Reel & Zoe Percival',
      emails: ['opinion@thecollegeview.ie', 'features@thecollegeview.ie'],
    ),
    ContactEntry(
      title: "Sports: Torna Mulconry, Ross Flanagan & Tiarnan O'Kelly",
      emails: ['sports@thecollegeview.ie'],
    ),
    ContactEntry(
      title: 'Lifestyle: Ruby Hegarty & Leah Doherty',
      emails: ['lifestyle@thecollegeview.ie'],
    ),
    ContactEntry(
      title: 'The Hype: Dylan Hand & Erica Elliott',
      emails: ['thehype@thecollegeview.ie'],
    ),
    ContactEntry(
      title: 'Satire & Cartoons: Ailish Connor & Shane Meleady',
      emails: ['satire@thecollegeview.ie'],
    ),
    ContactEntry(
      title: "Irish & Lang: Harry Byrne & Aisling O'Kane",
      emails: ['gaeilge@thecollegeview.ie'],
    ),
    ContactEntry(
      title: 'E-paper Layout Editors and Sub-editors',
      emails: ['production@thecollegeview.ie'],
    ),
    ContactEntry(
      title: 'Webmaster: Jake Farrell',
      emails: ['webmaster@dcumps.ie'],
    ),
  ];

  final String appName;
  final String appDescription;
  final String fallbackAuthorName;
  final bool enableAuthorTap;
  final String copyrightNotice;
  final String apiBase;
  final String website;
  final String websiteDomain;
  final String? _privacyPolicyUrl;
  final String instagramUrl;
  final String whatsappUrl;
  final String imageProxyUrl;
  final List<ContactEntry> contacts;

  const AppConfig({
    this.appName = defaultAppName,
    this.appDescription = defaultAppDescription,
    this.fallbackAuthorName = defaultFallbackAuthorName,
    this.enableAuthorTap = defaultEnableAuthorTap,
    this.copyrightNotice = defaultCopyrightNotice,
    this.apiBase = defaultApiBase,
    this.website = defaultWebsite,
    this.websiteDomain = defaultWebsiteDomain,
    String? privacyPolicyUrl,
    this.instagramUrl = defaultInstagramUrl,
    this.whatsappUrl = defaultWhatsappUrl,
    this.imageProxyUrl = defaultImageProxyUrl,
    this.contacts = defaultContacts,
  }) : _privacyPolicyUrl = privacyPolicyUrl;

  String get privacyPolicyUrl =>
      (_privacyPolicyUrl != null && _privacyPolicyUrl.isNotEmpty)
          ? _privacyPolicyUrl
          : '$website$defaultPrivacyPolicyPath';

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

  static String _pickString(List<dynamic> candidates, String fallback) {
    for (final value in candidates) {
      if (value != null) {
        final str = value.toString().trim();
        if (str.isNotEmpty) return str;
      }
    }
    return fallback;
  }

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    final urls = (json['urls'] as Map<String, dynamic>?) ?? {};
    final features = (json['features'] as Map<String, dynamic>?) ?? {};

    final website = _pickString(
      [json['website'], urls['website']],
      defaultWebsite,
    );

    final derivedDomain = Uri.tryParse(website)?.host ?? '';
    final parsedDomain = _pickString(
      [
        json['websiteDomain'],
        urls['websiteDomain'],
        if (derivedDomain.isNotEmpty) derivedDomain,
      ],
      defaultWebsiteDomain,
    );

    final rawEnableAuthorTap =
        json['enableAuthorTap'] ?? features['enableAuthorTap'];

    final rawContacts = json['contacts'];
    final contacts = rawContacts is List
        ? rawContacts
            .whereType<Map<String, dynamic>>()
            .map(ContactEntry.fromJson)
            .where((c) => c.title.isNotEmpty)
            .toList()
        : defaultContacts;

    final parsedPrivacyPolicy = _pickString(
      [
        json['privacyPolicyUrl'],
        json['privacyPolicy'],
        urls['privacyPolicy'],
        urls['privacyPolicyUrl'],
      ],
      '',
    );

    return AppConfig(
      appName: _pickString([json['appName'], json['name']], defaultAppName),
      appDescription: _pickString(
        [json['appDescription'], json['description']],
        defaultAppDescription,
      ),
      fallbackAuthorName: _pickString(
        [json['fallbackAuthorName'], json['authorFallback']],
        defaultFallbackAuthorName,
      ),
      enableAuthorTap: rawEnableAuthorTap is bool
          ? rawEnableAuthorTap
          : defaultEnableAuthorTap,
      copyrightNotice: _pickString(
        [json['copyrightNotice'], json['copyright']],
        defaultCopyrightNotice,
      ),
      apiBase: _pickString([json['apiBase'], urls['apiBase']], defaultApiBase),
      website: website,
      websiteDomain: parsedDomain,
      privacyPolicyUrl:
          parsedPrivacyPolicy.isNotEmpty ? parsedPrivacyPolicy : null,
      instagramUrl: _pickString(
        [json['instagramUrl'], urls['instagram'], urls['instagramUrl']],
        defaultInstagramUrl,
      ),
      whatsappUrl: _pickString(
        [json['whatsappUrl'], urls['whatsapp'], urls['whatsappUrl']],
        defaultWhatsappUrl,
      ),
      imageProxyUrl: _pickString(
        [json['imageProxyUrl'], urls['imageProxy'], urls['imageProxyUrl']],
        defaultImageProxyUrl,
      ),
      contacts: contacts.isNotEmpty ? contacts : defaultContacts,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'appName': appName,
      'appDescription': appDescription,
      'fallbackAuthorName': fallbackAuthorName,
      'enableAuthorTap': enableAuthorTap,
      'copyrightNotice': copyrightNotice,
      'urls': {
        'apiBase': apiBase,
        'website': website,
        'websiteDomain': websiteDomain,
        'privacyPolicy': privacyPolicyUrl,
        'instagram': instagramUrl,
        'whatsapp': whatsappUrl,
        'imageProxy': imageProxyUrl,
      },
      'contacts': contacts.map((c) => c.toJson()).toList(),
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
