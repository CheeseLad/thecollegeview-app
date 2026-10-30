import 'package:flutter_test/flutter_test.dart';
import 'package:thecollegeview/config/app_config.dart';
import 'package:thecollegeview/services/wp_api_service.dart';

void main() {
  setUp(() {
    AppConfig.resetForTesting();
  });

  tearDown(() {
    AppConfig.resetForTesting();
  });

  group('AppConfig Tests', () {
    test('Default values are correct', () {
      const config = AppConfig.defaults;
      expect(config.appName, 'The College View');
      expect(config.fallbackAuthorName, 'The College View');
      expect(config.apiBase, 'https://tcvappapi.jakefarrell.ie');
      expect(config.website, 'https://thecollegeview.ie');
      expect(config.websiteDomain, 'thecollegeview.ie');
      expect(
        config.privacyPolicyUrl,
        'https://thecollegeview.ie/the-college-view-mobile-app-privacy-policy',
      );
      expect(config.instagramUrl, 'https://instagram.com/thecollegeview');
      expect(config.whatsappUrl,
          'https://chat.whatsapp.com/C8Rwkvo7h7k4STz79ICfHV');
      expect(config.imageProxyUrl, 'https://images.weserv.nl/?url=');
      expect(config.contacts, isNotEmpty);
      expect(
          config.contacts.first.emails, contains('editor@thecollegeview.ie'));
    });

    test('AppConfig.fromJson parses custom contacts list', () {
      final json = {
        'contacts': [
          {
            'title': 'Editor: Jane Doe',
            'emails': ['editor@example.com', 'info@example.com'],
          },
        ],
      };

      final config = AppConfig.fromJson(json);

      expect(config.contacts.length, 1);
      expect(config.contacts.first.title, 'Editor: Jane Doe');
      expect(
        config.contacts.first.emails,
        ['editor@example.com', 'info@example.com'],
      );
    });

    test('AppConfig.fromJson parses nested urls JSON structure', () {
      final json = {
        'appName': 'Custom Paper',
        'appDescription': 'Custom Description',
        'fallbackAuthorName': 'Custom Staff',
        'copyrightNotice': '© 2026 Custom Paper',
        'urls': {
          'apiBase': 'https://api.custompaper.org',
          'website': 'https://custompaper.org',
          'websiteDomain': 'custompaper.org',
          'privacyPolicy': 'https://custompaper.org/privacy',
          'instagram': 'https://instagram.com/custompaper',
          'whatsapp': 'https://chat.whatsapp.com/custom',
          'imageProxy': 'https://images.custom.org/?url='
        }
      };

      final config = AppConfig.fromJson(json);

      expect(config.appName, 'Custom Paper');
      expect(config.appDescription, 'Custom Description');
      expect(config.fallbackAuthorName, 'Custom Staff');
      expect(config.copyrightNotice, '© 2026 Custom Paper');
      expect(config.apiBase, 'https://api.custompaper.org');
      expect(config.website, 'https://custompaper.org');
      expect(config.websiteDomain, 'custompaper.org');
      expect(config.privacyPolicyUrl, 'https://custompaper.org/privacy');
      expect(config.instagramUrl, 'https://instagram.com/custompaper');
      expect(config.whatsappUrl, 'https://chat.whatsapp.com/custom');
      expect(config.imageProxyUrl, 'https://images.custom.org/?url=');
    });

    test('AppConfig.fromJson parses flat JSON structure and derives domain',
        () {
      final json = {
        'name': 'Alt Paper',
        'apiBase': 'https://api.example.com',
        'website': 'https://example.com/subpath',
        'instagramUrl': 'https://instagram.com/alt',
        'whatsappUrl': 'https://chat.whatsapp.com/alt'
      };

      final config = AppConfig.fromJson(json);

      expect(config.appName, 'Alt Paper');
      expect(config.apiBase, 'https://api.example.com');
      expect(config.website, 'https://example.com/subpath');
      expect(config.websiteDomain, 'example.com');
      expect(config.instagramUrl, 'https://instagram.com/alt');
      expect(config.whatsappUrl, 'https://chat.whatsapp.com/alt');
      expect(config.fallbackAuthorName, AppConfig.defaultFallbackAuthorName);
    });

    test('AppConfig.toJson produces valid map matching fields', () {
      const config = AppConfig(
        appName: 'Test View',
        apiBase: 'https://api.testview.ie',
        website: 'https://testview.ie',
      );

      final json = config.toJson();

      expect(json['appName'], 'Test View');
      expect(json['urls']['apiBase'], 'https://api.testview.ie');
      expect(json['urls']['website'], 'https://testview.ie');
    });

    test('AppConfig.instance and WpApiService update dynamically', () {
      expect(AppConfig.instance.apiBase, 'https://tcvappapi.jakefarrell.ie');
      expect(AppConfig.instance.website, 'https://thecollegeview.ie');
      expect(AppConfig.instance.websiteDomain, 'thecollegeview.ie');
      expect(WpApiService.fallbackAuthorName, 'The College View');

      const customConfig = AppConfig(
        appName: 'New Horizon',
        fallbackAuthorName: 'New Horizon Desk',
        apiBase: 'https://api.horizon.ie',
        website: 'https://horizon.ie',
        websiteDomain: 'horizon.ie',
        instagramUrl: 'https://instagram.com/horizon',
        whatsappUrl: 'https://whatsapp.com/horizon',
      );

      AppConfig.setInstance(customConfig);

      expect(AppConfig.instance.apiBase, 'https://api.horizon.ie');
      expect(AppConfig.instance.website, 'https://horizon.ie');
      expect(AppConfig.instance.websiteDomain, 'horizon.ie');
      expect(AppConfig.instance.instagramUrl, 'https://instagram.com/horizon');
      expect(AppConfig.instance.whatsappUrl, 'https://whatsapp.com/horizon');
      expect(WpApiService.fallbackAuthorName, 'New Horizon Desk');
    });
  });
}
