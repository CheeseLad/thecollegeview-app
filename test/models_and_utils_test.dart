import 'package:flutter_test/flutter_test.dart';
import 'package:thecollegeview/models/article.dart';
import 'package:thecollegeview/models/category.dart';
import 'package:thecollegeview/models/saved_article.dart';
import 'package:thecollegeview/utils/html_utils.dart';
import 'package:thecollegeview/utils/deep_link_handler.dart';
import 'package:thecollegeview/services/wp_api_service.dart';
import 'package:thecollegeview/config/app_config.dart';
import 'package:thecollegeview/theme/app_theme.dart';

void main() {
  group('Article Model Tests', () {
    test('Article.fromJson parses complete JSON with _embedded', () {
      final json = {
        'id': 101,
        'date': '2026-10-14T12:00:00',
        'title': {'rendered': 'Test &amp; Article &#8216;Headline&#8217;'},
        'content': {'rendered': '<p>Article paragraph text &amp; more</p>'},
        'link': 'https://thecollegeview.ie/test-article',
        'author': 42,
        'featured_media': 88,
        'tags': [1, 2, 3],
        '_embedded': {
          'wp:featuredmedia': [
            {'source_url': 'https://thecollegeview.ie/image.jpg'}
          ],
          'author': [
            {'name': 'Jane Doe &amp; John Smith'}
          ]
        }
      };

      final article = Article.fromJson(json);

      expect(article.id, 101);
      expect(article.title, "Test & Article 'Headline'");
      expect(article.content, contains('Article paragraph text & more'));
      expect(article.link, 'https://thecollegeview.ie/test-article');
      expect(article.author, 42);
      expect(article.featuredMedia, 88);
      expect(article.tags, [1, 2, 3]);
      expect(article.embeddedFeaturedMediaUrl,
          'https://thecollegeview.ie/image.jpg');
      expect(article.embeddedAuthorName, isNull);
    });

    test('Article.fromJson safely handles missing and null fields', () {
      final json = <String, dynamic>{
        'id': null,
        'title': null,
        'content': null,
        'tags': null,
      };

      final article = Article.fromJson(json);

      expect(article.id, 0);
      expect(article.title, '');
      expect(article.content, '');
      expect(article.tags, isEmpty);
      expect(article.embeddedFeaturedMediaUrl, isNull);
      expect(article.embeddedAuthorName, isNull);
    });
  });

  group('SavedArticle Model Tests', () {
    test('Conversion to and from Map preserves all fields', () {
      final now = DateTime.now();
      final saved = SavedArticle(
        article: const Article(
          id: 55,
          date: '2026-10-14T10:00:00',
          title: 'Saved Title',
          content: '<p>Saved content</p>',
          link: 'https://thecollegeview.ie/saved',
          author: 7,
          featuredMedia: 12,
          tags: [10, 20],
          embeddedFeaturedMediaUrl: 'https://thecollegeview.ie/img.png',
          embeddedAuthorName: 'Author Name',
        ),
        categoryName: 'News',
        savedAt: now,
        tagNames: ['News', 'Campus'],
      );

      final map = saved.toMap();
      final reconstructed = SavedArticle.fromMap(map);

      expect(reconstructed.id, 55);
      expect(reconstructed.article.title, 'Saved Title');
      expect(reconstructed.categoryName, 'News');
      expect(reconstructed.article.embeddedFeaturedMediaUrl,
          'https://thecollegeview.ie/img.png');
      expect(reconstructed.article.embeddedAuthorName, 'Author Name');
      expect(reconstructed.article.tags, [10, 20]);
      expect(reconstructed.tagNames, ['News', 'Campus']);
      expect(reconstructed.savedAt.year, now.year);
    });
  });

  group('Category Model Tests', () {
    test('Category subcategories list is mutable and safe to modify', () {
      final category = Category(
        id: 1,
        name: 'News',
      );

      expect(category.subcategories, isEmpty);
      // Verify adding does not throw UnsupportedOperationException
      expect(() {
        category.subcategories.add(Category(id: 2, name: 'Campus News'));
      }, returnsNormally);
      expect(category.subcategories.length, 1);
    });
  });

  group('HtmlUtils Tests', () {
    test('decodeHtmlEntities decodes common entities', () {
      expect(HtmlUtils.decodeHtmlEntities('&amp;'), '&');
      expect(HtmlUtils.decodeHtmlEntities('&#8216;test&#8217;'), "'test'");
      expect(HtmlUtils.decodeHtmlEntities('&quot;hello&quot;'), '"hello"');
    });

    test('decodeHtmlEntitiesPreserveTags preserves tags while decoding', () {
      const html = '<p>Price: &euro;10 &amp; shipping &lt; free</p>';
      final result = HtmlUtils.decodeHtmlEntitiesPreserveTags(html);
      expect(result, contains('<p>'));
      expect(result, contains('€10'));
      expect(result, contains('&'));
    });
  });

  group('WpApiService Author Tests', () {
    test('Fallback author name is The College View', () {
      expect(WpApiService.fallbackAuthorName, 'The College View');
    });

    test('fetchAuthorName with empty URL returns fallback author name',
        () async {
      final author = await WpApiService.fetchAuthorName('');
      expect(author, 'The College View');
    });

    test('Cached author name is returned when present', () async {
      const url = 'https://thecollegeview.ie/cached-test-article';
      WpApiService.cacheAuthorName(url, 'John Journalist');
      expect(WpApiService.getCachedAuthorName(url), 'John Journalist');
      final fetched = await WpApiService.fetchAuthorName(url);
      expect(fetched, 'John Journalist');
    });

    test('Privacy policy URL is properly configured', () {
      expect(
        AppConfig.instance.privacyPolicyUrl,
        'https://thecollegeview.ie/the-college-view-mobile-app-privacy-policy',
      );
    });
  });

  group('Reader Font Size & Deep Link Tests', () {
    test('ThemeProvider clamps and labels articleFontSize accurately', () {
      final themeProvider = ThemeProvider();
      expect(themeProvider.articleFontSize, 16.0);
      expect(themeProvider.articleFontSizeLabel, 'Medium');

      themeProvider.setArticleFontSize(14.0);
      expect(themeProvider.articleFontSize, 14.0);
      expect(themeProvider.articleFontSizeLabel, 'Small');

      themeProvider.setArticleFontSize(19.0);
      expect(themeProvider.articleFontSize, 19.0);
      expect(themeProvider.articleFontSizeLabel, 'Large');

      themeProvider.setArticleFontSize(30.0);
      expect(themeProvider.articleFontSize, ThemeProvider.maxFontSize);
      expect(themeProvider.articleFontSizeLabel, 'Extra Large');
    });

    test('DeepLinkHandler recognizes internal website domains and privacy policy', () {
      expect(DeepLinkHandler.isInternalWebsiteHost('thecollegeview.ie'), isTrue);
      expect(DeepLinkHandler.isInternalWebsiteHost('www.thecollegeview.ie'), isTrue);
      expect(DeepLinkHandler.isInternalWebsiteHost('google.com'), isFalse);

      expect(
        DeepLinkHandler.isPrivacyPolicyPath(
          Uri.parse('https://thecollegeview.ie/the-college-view-mobile-app-privacy-policy'),
        ),
        isTrue,
      );
      expect(
        DeepLinkHandler.isPrivacyPolicyPath(
          Uri.parse('https://thecollegeview.ie/2026/10/sample-article/'),
        ),
        isFalse,
      );
    });

    test('AppConfig enableAuthorTap defaults to false and parses from JSON', () {
      expect(AppConfig.defaults.enableAuthorTap, isFalse);
      final enabledConfig = AppConfig.fromJson({'enableAuthorTap': true});
      expect(enabledConfig.enableAuthorTap, isTrue);
      final disabledConfig = AppConfig.fromJson({'enableAuthorTap': false});
      expect(disabledConfig.enableAuthorTap, isFalse);
    });
  });
}
