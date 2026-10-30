import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thecollegeview/main.dart';
import 'package:thecollegeview/providers/saved_articles_provider.dart';
import 'package:thecollegeview/theme/app_theme.dart';
import 'package:thecollegeview/utils/display_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('flutter_display_mode');

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('DisplayUtils Platform Guard Tests', () {
    test('Non-Android platforms complete enableHighRefreshRate without error',
        () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      await expectLater(DisplayUtils.enableHighRefreshRate(), completes);

      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      await expectLater(DisplayUtils.enableHighRefreshRate(), completes);

      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      await expectLater(DisplayUtils.enableHighRefreshRate(), completes);
    });

    test('Non-Android platforms return null for refresh rates', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      expect(await DisplayUtils.getActiveRefreshRate(), isNull);
      expect(await DisplayUtils.getHighestRefreshRate(), isNull);
    });
  });

  group('DisplayUtils Android Mock Tests', () {
    test('Android queries and sets the highest refresh rate mode', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;

      int? requestedModeId;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        if (call.method == 'getSupportedModes') {
          return [
            {'id': 1, 'width': 1080, 'height': 2400, 'refreshRate': 60.0},
            {'id': 2, 'width': 1080, 'height': 2400, 'refreshRate': 120.0},
            {'id': 3, 'width': 1080, 'height': 2400, 'refreshRate': 90.0},
          ];
        } else if (call.method == 'getActiveMode') {
          return {'id': 1, 'width': 1080, 'height': 2400, 'refreshRate': 60.0};
        } else if (call.method == 'setPreferredMode') {
          requestedModeId = call.arguments['mode'] as int?;
          return null;
        }
        return null;
      });

      await DisplayUtils.enableHighRefreshRate();

      expect(requestedModeId, 2); // Mode 2 has 120Hz
    });

    test(
        'Android getActiveRefreshRate and getHighestRefreshRate return correct values',
        () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        if (call.method == 'getActiveMode') {
          return {'id': 2, 'width': 1080, 'height': 2400, 'refreshRate': 120.0};
        } else if (call.method == 'getSupportedModes') {
          return [
            {'id': 1, 'width': 1080, 'height': 2400, 'refreshRate': 60.0},
            {'id': 2, 'width': 1080, 'height': 2400, 'refreshRate': 120.0},
          ];
        }
        return null;
      });

      final activeRate = await DisplayUtils.getActiveRefreshRate();
      final highestRate = await DisplayUtils.getHighestRefreshRate();

      expect(activeRate, 120.0);
      expect(highestRate, 120.0);
    });

    test('Gracefully handles PlatformException on unsupported devices',
        () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        throw PlatformException(
          code: 'UNAVAILABLE',
          message: 'Display modes not supported on this device',
        );
      });

      await expectLater(DisplayUtils.enableHighRefreshRate(), completes);
      expect(await DisplayUtils.getActiveRefreshRate(), isNull);
      expect(await DisplayUtils.getHighestRefreshRate(), isNull);
    });
  });

  group('MyApp Lifecycle Integration Tests', () {
    testWidgets('MyApp handles AppLifecycleState.resumed without error',
        (WidgetTester tester) async {
      final savedArticlesProvider = SavedArticlesProvider();
      final themeProvider = ThemeProvider();

      await tester.pumpWidget(
        MyApp(
          savedArticlesProvider: savedArticlesProvider,
          themeProvider: themeProvider,
        ),
      );

      // Simulate app transitioning to resumed
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();

      expect(find.byType(MyApp), findsOneWidget);
    });
  });
}
