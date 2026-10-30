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
  static const String defaultLogoAssetPath = 'assets/logo.png';
  static const String defaultContactIntroText =
      'Please email press releases to the appropriate section only.';
  static const String defaultCopyrightNotice =
      '© The College View 1999-2026 - Maintained by Jake Farrell';
  static const String defaultAboutHtml = '''
<p>The College View is Dublin City University's only student newspaper, independently run voluntarily by students affiliated to DCU's Journalism Society. The newspaper was first published in 1999 after changing its name from The Bullsheet, its predecessor.</p>
<p>The College View has nine sections – News, Opinions, Features, Irish, Sports, Lifestyle, Satire, Science and Tech and our arts section, The Hype. These sections cover everything from DCU student issues to national student issues, humour and satire to life through the eyes of students, as well as extensive sports coverage and analysis. The Irish section is written and edited by students studying Journalism through Irish in DCU.</p>
<p>The College View is published fortnightly on Wednesday, with six issues per semester and is circulated among 12,000 students as well as DCU lecturers and staff.</p>
<h3>Community standards and participation guidelines</h3>
<p>The College View reserves the right to delete comments which it deems abusive. Such comments are deemed to be directly insulting, racist, sexist, xenophobic, or homophobic to other readers or its staff of journalists and writers.</p>
<p>The College View welcomes criticism and opposing viewpoints through constructive and rational debate and wishes to create an atmosphere which encourages an open dialogue.</p>
''';

  // Feature flags
  static const bool defaultEnableAuthorTap = false;
  static const bool defaultUseRemoteAboutPage = true;
  static const bool defaultEnableRelatedArticles = true;
  static const bool defaultEnableTagChips = true;
  static const bool defaultEnableShareButton = true;
  static const bool defaultForceOfflineMode = false;

  // URLs
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

  // API & Pagination defaults
  static const String defaultAuthorSubheadingEndpointPath = '/get-subheading';
  static const String defaultAboutPageSlug = 'about';
  static const int defaultPostsPerPage = 10;
  static const int defaultSearchResultsPerPage = 20;
  static const int defaultRelatedArticlesCount = 3;
  static const int defaultRelatedArticlesFetchPool = 10;
  static const int defaultCategoriesPerPage = 100;
  static const int defaultHttpTimeoutSeconds = 12;
  static const int defaultSearchDebounceMs = 350;
  static const List<String> defaultNonArticleSlugs = [
    'about',
    'contact',
    'category',
    'tag',
    'author',
    'search',
    'wp-admin',
    'wp-login.php',
    'feed',
  ];

  // Cache defaults
  static const int defaultFreshCacheTtlMinutes = 60;
  static const int defaultStaleCacheTtlDays = 7;
  static const int defaultMaxCacheEntries = 150;

  // Theme & Reader defaults
  static const String defaultPrimarySeedColorHex = '#1976D2';
  static const double defaultMinFontSize = 13.0;
  static const double defaultReaderFontSize = 16.0;
  static const double defaultMaxFontSize = 24.0;

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
  final String logoAssetPath;
  final String contactIntroText;
  final String copyrightNotice;
  final String aboutHtml;

  // Feature flags
  final bool enableAuthorTap;
  final bool useRemoteAboutPage;
  final bool enableRelatedArticles;
  final bool enableTagChips;
  final bool enableShareButton;
  final bool forceOfflineMode;

  // URLs
  final String apiBase;
  final String website;
  final String websiteDomain;
  final String? _privacyPolicyUrl;
  final String instagramUrl;
  final String whatsappUrl;
  final String tiktokUrl;
  final String xUrl;
  final String linkedinUrl;
  final String youtubeUrl;
  final String spotifyUrl;
  final String imageProxyUrl;

  // API & Pagination
  final String authorSubheadingEndpointPath;
  final String aboutPageSlug;
  final int postsPerPage;
  final int searchResultsPerPage;
  final int relatedArticlesCount;
  final int relatedArticlesFetchPool;
  final int categoriesPerPage;
  final int httpTimeoutSeconds;
  final int searchDebounceMs;
  final List<String> nonArticleSlugs;

  // Cache
  final int freshCacheTtlMinutes;
  final int staleCacheTtlDays;
  final int maxCacheEntries;

  // Theme & Reader
  final String primarySeedColorHex;
  final double minFontSize;
  final double defaultFontSize;
  final double maxFontSize;

  final List<ContactEntry> contacts;

  const AppConfig({
    this.appName = defaultAppName,
    this.appDescription = defaultAppDescription,
    this.fallbackAuthorName = defaultFallbackAuthorName,
    this.logoAssetPath = defaultLogoAssetPath,
    this.contactIntroText = defaultContactIntroText,
    this.copyrightNotice = defaultCopyrightNotice,
    this.aboutHtml = defaultAboutHtml,
    this.enableAuthorTap = defaultEnableAuthorTap,
    this.useRemoteAboutPage = defaultUseRemoteAboutPage,
    this.enableRelatedArticles = defaultEnableRelatedArticles,
    this.enableTagChips = defaultEnableTagChips,
    this.enableShareButton = defaultEnableShareButton,
    this.forceOfflineMode = defaultForceOfflineMode,
    this.apiBase = defaultApiBase,
    this.website = defaultWebsite,
    this.websiteDomain = defaultWebsiteDomain,
    String? privacyPolicyUrl,
    this.instagramUrl = defaultInstagramUrl,
    this.whatsappUrl = defaultWhatsappUrl,
    this.tiktokUrl = '',
    this.xUrl = '',
    this.linkedinUrl = '',
    this.youtubeUrl = '',
    this.spotifyUrl = '',
    this.imageProxyUrl = defaultImageProxyUrl,
    this.authorSubheadingEndpointPath = defaultAuthorSubheadingEndpointPath,
    this.aboutPageSlug = defaultAboutPageSlug,
    this.postsPerPage = defaultPostsPerPage,
    this.searchResultsPerPage = defaultSearchResultsPerPage,
    this.relatedArticlesCount = defaultRelatedArticlesCount,
    this.relatedArticlesFetchPool = defaultRelatedArticlesFetchPool,
    this.categoriesPerPage = defaultCategoriesPerPage,
    this.httpTimeoutSeconds = defaultHttpTimeoutSeconds,
    this.searchDebounceMs = defaultSearchDebounceMs,
    this.nonArticleSlugs = defaultNonArticleSlugs,
    this.freshCacheTtlMinutes = defaultFreshCacheTtlMinutes,
    this.staleCacheTtlDays = defaultStaleCacheTtlDays,
    this.maxCacheEntries = defaultMaxCacheEntries,
    this.primarySeedColorHex = defaultPrimarySeedColorHex,
    this.minFontSize = defaultMinFontSize,
    this.defaultFontSize = defaultReaderFontSize,
    this.maxFontSize = defaultMaxFontSize,
    this.contacts = defaultContacts,
  }) : _privacyPolicyUrl = privacyPolicyUrl;

  String get privacyPolicyUrl =>
      (_privacyPolicyUrl != null && _privacyPolicyUrl.isNotEmpty)
          ? _privacyPolicyUrl
          : '$website$defaultPrivacyPolicyPath';

  int get freshCacheTtlMs => freshCacheTtlMinutes * 60 * 1000;
  int get staleCacheTtlMs => staleCacheTtlDays * 24 * 60 * 60 * 1000;

  Color get primarySeedColor {
    var hex = primarySeedColorHex.trim().replaceAll('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    final parsed = int.tryParse(hex, radix: 16);
    return parsed != null ? Color(parsed) : const Color(0xFF1976D2);
  }

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

  static bool _pickBool(List<dynamic> candidates, bool fallback) {
    for (final value in candidates) {
      if (value is bool) return value;
    }
    return fallback;
  }

  static int _pickInt(List<dynamic> candidates, int fallback, {int min = 1}) {
    for (final value in candidates) {
      if (value is num && value.toInt() >= min) return value.toInt();
      if (value != null) {
        final parsed = int.tryParse(value.toString().trim());
        if (parsed != null && parsed >= min) return parsed;
      }
    }
    return fallback;
  }

  static double _pickDouble(
    List<dynamic> candidates,
    double fallback, {
    double min = 1.0,
  }) {
    for (final value in candidates) {
      if (value is num && value.toDouble() >= min) return value.toDouble();
      if (value != null) {
        final parsed = double.tryParse(value.toString().trim());
        if (parsed != null && parsed >= min) return parsed;
      }
    }
    return fallback;
  }

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    final urls = (json['urls'] as Map<String, dynamic>?) ?? {};
    final features = (json['features'] as Map<String, dynamic>?) ?? {};
    final api = (json['api'] as Map<String, dynamic>?) ?? {};
    final cache = (json['cache'] as Map<String, dynamic>?) ?? {};
    final theme = (json['theme'] as Map<String, dynamic>?) ?? {};
    final reader = (json['reader'] as Map<String, dynamic>?) ?? {};

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

    final rawContacts = json['contacts'];
    final contacts = rawContacts is List
        ? rawContacts
            .whereType<Map<String, dynamic>>()
            .map(ContactEntry.fromJson)
            .where((c) => c.title.isNotEmpty)
            .toList()
        : defaultContacts;

    final rawNonArticleSlugs =
        json['nonArticleSlugs'] ?? api['nonArticleSlugs'];
    final nonArticleSlugs = rawNonArticleSlugs is List
        ? rawNonArticleSlugs
            .map((s) => s.toString().trim().toLowerCase())
            .where((s) => s.isNotEmpty)
            .toList()
        : defaultNonArticleSlugs;

    final parsedPrivacyPolicy = _pickString(
      [
        json['privacyPolicyUrl'],
        json['privacyPolicy'],
        urls['privacyPolicy'],
        urls['privacyPolicyUrl'],
      ],
      '',
    );

    final rawEndpointPath = _pickString(
      [
        json['authorSubheadingEndpointPath'],
        api['authorSubheadingEndpointPath'],
        api['subheadingEndpoint'],
      ],
      defaultAuthorSubheadingEndpointPath,
    );
    final normalizedEndpointPath = rawEndpointPath.startsWith('/')
        ? rawEndpointPath
        : '/$rawEndpointPath';

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
      logoAssetPath: _pickString(
        [json['logoAssetPath'], theme['logoAssetPath']],
        defaultLogoAssetPath,
      ),
      contactIntroText: _pickString(
        [json['contactIntroText'], json['contactIntro']],
        defaultContactIntroText,
      ),
      copyrightNotice: _pickString(
        [json['copyrightNotice'], json['copyright']],
        defaultCopyrightNotice,
      ),
      aboutHtml: _pickString(
        [json['aboutHtml'], json['about']],
        defaultAboutHtml,
      ),
      enableAuthorTap: _pickBool(
        [json['enableAuthorTap'], features['enableAuthorTap']],
        defaultEnableAuthorTap,
      ),
      useRemoteAboutPage: _pickBool(
        [json['useRemoteAboutPage'], features['useRemoteAboutPage']],
        defaultUseRemoteAboutPage,
      ),
      enableRelatedArticles: _pickBool(
        [json['enableRelatedArticles'], features['enableRelatedArticles']],
        defaultEnableRelatedArticles,
      ),
      enableTagChips: _pickBool(
        [json['enableTagChips'], features['enableTagChips']],
        defaultEnableTagChips,
      ),
      enableShareButton: _pickBool(
        [json['enableShareButton'], features['enableShareButton']],
        defaultEnableShareButton,
      ),
      forceOfflineMode: _pickBool(
        [
          json['forceOfflineMode'],
          json['offlineMode'],
          features['forceOfflineMode'],
          features['offlineMode'],
        ],
        defaultForceOfflineMode,
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
      tiktokUrl: _pickString(
        [json['tiktokUrl'], urls['tiktok'], urls['tiktokUrl']],
        '',
      ),
      xUrl: _pickString(
        [json['xUrl'], urls['x'], urls['twitter'], urls['xUrl']],
        '',
      ),
      linkedinUrl: _pickString(
        [json['linkedinUrl'], urls['linkedin'], urls['linkedinUrl']],
        '',
      ),
      youtubeUrl: _pickString(
        [json['youtubeUrl'], urls['youtube'], urls['youtubeUrl']],
        '',
      ),
      spotifyUrl: _pickString(
        [json['spotifyUrl'], urls['spotify'], urls['spotifyUrl']],
        '',
      ),
      imageProxyUrl: _pickString(
        [json['imageProxyUrl'], urls['imageProxy'], urls['imageProxyUrl']],
        defaultImageProxyUrl,
      ),
      authorSubheadingEndpointPath: normalizedEndpointPath,
      aboutPageSlug: _pickString(
        [json['aboutPageSlug'], api['aboutPageSlug']],
        defaultAboutPageSlug,
      ),
      postsPerPage: _pickInt(
        [json['postsPerPage'], api['postsPerPage']],
        defaultPostsPerPage,
      ),
      searchResultsPerPage: _pickInt(
        [json['searchResultsPerPage'], api['searchResultsPerPage']],
        defaultSearchResultsPerPage,
      ),
      relatedArticlesCount: _pickInt(
        [json['relatedArticlesCount'], api['relatedArticlesCount']],
        defaultRelatedArticlesCount,
      ),
      relatedArticlesFetchPool: _pickInt(
        [json['relatedArticlesFetchPool'], api['relatedArticlesFetchPool']],
        defaultRelatedArticlesFetchPool,
      ),
      categoriesPerPage: _pickInt(
        [json['categoriesPerPage'], api['categoriesPerPage']],
        defaultCategoriesPerPage,
      ),
      httpTimeoutSeconds: _pickInt(
        [json['httpTimeoutSeconds'], api['httpTimeoutSeconds']],
        defaultHttpTimeoutSeconds,
      ),
      searchDebounceMs: _pickInt(
        [json['searchDebounceMs'], api['searchDebounceMs']],
        defaultSearchDebounceMs,
        min: 0,
      ),
      nonArticleSlugs:
          nonArticleSlugs.isNotEmpty ? nonArticleSlugs : defaultNonArticleSlugs,
      freshCacheTtlMinutes: _pickInt(
        [json['freshCacheTtlMinutes'], cache['freshCacheTtlMinutes']],
        defaultFreshCacheTtlMinutes,
      ),
      staleCacheTtlDays: _pickInt(
        [json['staleCacheTtlDays'], cache['staleCacheTtlDays']],
        defaultStaleCacheTtlDays,
      ),
      maxCacheEntries: _pickInt(
        [json['maxCacheEntries'], cache['maxCacheEntries']],
        defaultMaxCacheEntries,
      ),
      primarySeedColorHex: _pickString(
        [json['primarySeedColorHex'], theme['primarySeedColorHex']],
        defaultPrimarySeedColorHex,
      ),
      minFontSize: _pickDouble(
        [json['minFontSize'], reader['minFontSize']],
        defaultMinFontSize,
        min: 8.0,
      ),
      defaultFontSize: _pickDouble(
        [json['defaultFontSize'], reader['defaultFontSize']],
        defaultReaderFontSize,
        min: 8.0,
      ),
      maxFontSize: _pickDouble(
        [json['maxFontSize'], reader['maxFontSize']],
        defaultMaxFontSize,
        min: 10.0,
      ),
      contacts: contacts.isNotEmpty ? contacts : defaultContacts,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'appName': appName,
      'appDescription': appDescription,
      'fallbackAuthorName': fallbackAuthorName,
      'logoAssetPath': logoAssetPath,
      'contactIntroText': contactIntroText,
      'enableAuthorTap': enableAuthorTap,
      'copyrightNotice': copyrightNotice,
      'aboutHtml': aboutHtml,
      'features': {
        'enableAuthorTap': enableAuthorTap,
        'useRemoteAboutPage': useRemoteAboutPage,
        'enableRelatedArticles': enableRelatedArticles,
        'enableTagChips': enableTagChips,
        'enableShareButton': enableShareButton,
        'forceOfflineMode': forceOfflineMode,
      },
      'urls': {
        'apiBase': apiBase,
        'website': website,
        'websiteDomain': websiteDomain,
        'privacyPolicy': privacyPolicyUrl,
        'instagram': instagramUrl,
        'whatsapp': whatsappUrl,
        'tiktok': tiktokUrl,
        'x': xUrl,
        'linkedin': linkedinUrl,
        'youtube': youtubeUrl,
        'spotify': spotifyUrl,
        'imageProxy': imageProxyUrl,
      },
      'api': {
        'authorSubheadingEndpointPath': authorSubheadingEndpointPath,
        'aboutPageSlug': aboutPageSlug,
        'postsPerPage': postsPerPage,
        'searchResultsPerPage': searchResultsPerPage,
        'relatedArticlesCount': relatedArticlesCount,
        'relatedArticlesFetchPool': relatedArticlesFetchPool,
        'categoriesPerPage': categoriesPerPage,
        'httpTimeoutSeconds': httpTimeoutSeconds,
        'searchDebounceMs': searchDebounceMs,
        'nonArticleSlugs': nonArticleSlugs,
      },
      'cache': {
        'freshCacheTtlMinutes': freshCacheTtlMinutes,
        'staleCacheTtlDays': staleCacheTtlDays,
        'maxCacheEntries': maxCacheEntries,
      },
      'theme': {
        'primarySeedColorHex': primarySeedColorHex,
        'logoAssetPath': logoAssetPath,
      },
      'reader': {
        'minFontSize': minFontSize,
        'defaultFontSize': defaultFontSize,
        'maxFontSize': maxFontSize,
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
