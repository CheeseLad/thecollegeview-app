import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:thecollegeview/widgets/skeleton.dart';
import 'package:thecollegeview/widgets/article_list.dart';
import 'package:thecollegeview/widgets/network_image_with_fallback.dart';
import 'package:thecollegeview/providers/article_provider.dart';
import 'package:thecollegeview/models/article.dart';

void main() {
  group('Skeleton Components Tests', () {
    testWidgets('SkeletonBox renders standalone without ancestral SkeletonShimmer',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonBox(
              width: 100,
              height: 20,
            ),
          ),
        ),
      );

      expect(find.byType(SkeletonBox), findsOneWidget);
      final container = tester.widget<Container>(find.descendant(
        of: find.byType(SkeletonBox),
        matching: find.byType(Container),
      ));
      expect(container.constraints?.maxWidth, 100);
      expect(container.constraints?.maxHeight, 20);
    });

    testWidgets('SkeletonShimmer provides scope and renders children',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonShimmer(
              child: Column(
                children: [
                  SkeletonBox(width: 80, height: 16),
                  SkeletonLine(width: 120, height: 14),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.byType(SkeletonShimmer), findsOneWidget);
      expect(find.byType(SkeletonShimmerScope), findsOneWidget);
      expect(find.byType(SkeletonBox), findsNWidgets(2)); // SkeletonLine uses SkeletonBox
      expect(find.byType(SkeletonLine), findsOneWidget);
    });

    testWidgets('ArticleCardSkeleton renders styled card structure',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ArticleCardSkeleton(),
          ),
        ),
      );

      expect(find.byType(ArticleCardSkeleton), findsOneWidget);
      expect(find.byType(Card), findsOneWidget);
      expect(find.byType(SkeletonBox), findsWidgets);
      expect(find.byType(SkeletonLine), findsWidgets);
    });

    testWidgets('ArticleListSkeleton renders multiple ArticleCardSkeletons in ListView',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ArticleListSkeleton(itemCount: 4),
          ),
        ),
      );

      expect(find.byType(ArticleListSkeleton), findsOneWidget);
      expect(find.byType(ListView), findsOneWidget);
      expect(find.byType(ArticleCardSkeleton), findsWidgets);
    });

    testWidgets('ArticleDetailSkeleton renders complete article structure',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ArticleDetailSkeleton(),
          ),
        ),
      );

      expect(find.byType(ArticleDetailSkeleton), findsOneWidget);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(find.byType(SkeletonBox), findsWidgets);
      expect(find.byType(SkeletonLine), findsWidgets);
    });

    testWidgets('AboutScreenSkeleton renders styled about card skeleton',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AboutScreenSkeleton(),
          ),
        ),
      );

      expect(find.byType(AboutScreenSkeleton), findsOneWidget);
      expect(find.byType(Card), findsOneWidget);
      expect(find.byType(SkeletonBox), findsWidgets);
    });

    testWidgets('RelatedArticlesSkeleton renders related section skeleton',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RelatedArticlesSkeleton(),
          ),
        ),
      );

      expect(find.byType(RelatedArticlesSkeleton), findsOneWidget);
      expect(find.byType(ArticleCardSkeleton), findsNWidgets(2));
    });

    testWidgets('NetworkImageWithFallback shows SkeletonBox placeholder',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NetworkImageWithFallback(
              imageUrl: 'https://thecollegeview.ie/test-loading.jpg',
              fallbackAssetPath: 'assets/logo.png',
              width: 100,
              height: 100,
            ),
          ),
        ),
      );

      expect(find.byType(SkeletonBox), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });

  group('ArticleList Skeleton Integration Tests', () {
    testWidgets('ArticleList displays ArticleListSkeleton when loading with empty list',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider(
              create: (_) => ArticleProvider(),
              child: const ArticleList(
                categoryName: 'News',
                articles: [],
                isLoading: true,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(ArticleListSkeleton), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('ArticleList shows ArticleCardSkeleton at bottom for pagination loading',
        (tester) async {
      final dummyArticles = List<Article>.generate(
        3,
        (i) => Article(
          id: i + 1,
          date: '2026-10-14T10:00:00',
          title: 'Article #$i',
          content: 'Content #$i',
          link: 'https://thecollegeview.ie/article-$i',
          author: 1,
          featuredMedia: 0,
          tags: const [],
        ),
      );

      final provider = ArticleProvider();
      provider.articles.addAll(dummyArticles);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<ArticleProvider>.value(
              value: provider,
              child: const ArticleList(
                categoryName: 'News',
                isLoading: true, // bottom pagination loading
              ),
            ),
          ),
        ),
      );

      expect(find.byType(ArticleCardSkeleton), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });
}
