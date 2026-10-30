import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/cache_service.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _boxName = 'settings';
  static const String _themeKey = 'themeMode';
  static const String _fontSizeKey = 'articleFontSize';

  static const double minFontSize = 13.0;
  static const double defaultFontSize = 16.0;
  static const double maxFontSize = 24.0;

  ThemeMode _themeMode = ThemeMode.system;
  double _articleFontSize = defaultFontSize;
  Box? _box;

  ThemeMode get themeMode => _themeMode;
  double get articleFontSize => _articleFontSize;

  Future<void> init() async {
    try {
      _box = await CacheService.openBoxWithRecovery(_boxName);
      final savedMode = _box?.get(_themeKey) as String?;
      _themeMode = switch (savedMode) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };

      final savedFontSize = _box?.get(_fontSizeKey);
      if (savedFontSize is num) {
        _articleFontSize =
            savedFontSize.toDouble().clamp(minFontSize, maxFontSize);
      }
    } catch (_) {
      _themeMode = ThemeMode.system;
      _articleFontSize = defaultFontSize;
    }
    notifyListeners();
  }

  String get articleFontSizeLabel {
    if (_articleFontSize <= 14.5) return 'Small';
    if (_articleFontSize <= 17.0) return 'Medium';
    if (_articleFontSize <= 20.0) return 'Large';
    return 'Extra Large';
  }

  void setArticleFontSize(double size) {
    final clamped = size.clamp(minFontSize, maxFontSize);
    if (_articleFontSize == clamped) return;
    _articleFontSize = clamped;
    if (_box != null && _box!.isOpen) {
      _box!.put(_fontSizeKey, _articleFontSize);
    }
    notifyListeners();
  }

  void cycleThemeMode() {
    switch (_themeMode) {
      case ThemeMode.system:
        _themeMode = ThemeMode.light;
        break;
      case ThemeMode.light:
        _themeMode = ThemeMode.dark;
        break;
      case ThemeMode.dark:
        _themeMode = ThemeMode.system;
        break;
    }
    _saveThemeMode(_themeMode);
    notifyListeners();
  }

  void _saveThemeMode(ThemeMode mode) {
    if (_box != null && _box!.isOpen) {
      String value = 'system';
      if (mode == ThemeMode.light) value = 'light';
      if (mode == ThemeMode.dark) value = 'dark';
      _box!.put(_themeKey, value);
    }
  }
}

class AppTheme {
  static const Color lightArticleDetailBackgroundColor = Color(0xFFF7F8FA);
  static const Color darkArticleDetailBackgroundColor = Color(0xFF121212);

  static const SystemUiOverlayStyle lightSystemOverlayStyle =
      SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemStatusBarContrastEnforced: false,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.dark,
    systemNavigationBarContrastEnforced: false,
  );

  static const SystemUiOverlayStyle darkSystemOverlayStyle =
      SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemStatusBarContrastEnforced: false,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
    systemNavigationBarContrastEnforced: false,
  );

  static SystemUiOverlayStyle systemOverlayStyleFor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkSystemOverlayStyle
        : lightSystemOverlayStyle;
  }

  static Color articleDetailBackgroundColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkArticleDetailBackgroundColor
        : lightArticleDetailBackgroundColor;
  }

  static String _toCssHex(Color color) {
    final r = (color.r * 255.0).round().clamp(0, 255).toRadixString(16).padLeft(2, '0');
    final g = (color.g * 255.0).round().clamp(0, 255).toRadixString(16).padLeft(2, '0');
    final b = (color.b * 255.0).round().clamp(0, 255).toRadixString(16).padLeft(2, '0');
    return '#$r$g$b';
  }

  static String _toCssRgba(Color color, double opacity) {
    final r = (color.r * 255.0).round().clamp(0, 255);
    final g = (color.g * 255.0).round().clamp(0, 255);
    final b = (color.b * 255.0).round().clamp(0, 255);
    return 'rgba($r, $g, $b, ${opacity.toStringAsFixed(2)})';
  }

  /// Provides editorial CSS rules for [HtmlWidget] elements (`blockquote`,
  /// `figcaption`, `figure`, `h2`, `h3`, `h4`, `p`, `img`, `a`).
  static Map<String, String>? editorialHtmlStyles(
    BuildContext context,
    String? localName,
  ) {
    if (localName == null) return null;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    switch (localName) {
      case 'blockquote':
        return {
          'border-left': '4px solid ${_toCssHex(colorScheme.primary)}',
          'background-color':
              _toCssRgba(colorScheme.primaryContainer, isDark ? 0.25 : 0.38),
          'font-style': 'italic',
          'margin': '18px 0',
          'padding': '12px 16px',
          'border-radius': '0 8px 8px 0',
          'color': _toCssHex(colorScheme.onSurface),
        };
      case 'figcaption':
        return {
          'font-size': '0.85em',
          'line-height': '1.4',
          'color': _toCssHex(colorScheme.onSurfaceVariant),
          'text-align': 'center',
          'font-style': 'italic',
          'margin': '6px 0 4px 0',
        };
      case 'figure':
        return {
          'margin': '18px 0',
          'padding': '0',
        };
      case 'img':
        return {
          'border-radius': '10px',
          'margin': '4px 0',
        };
      case 'h2':
        return {
          'font-size': '1.35em',
          'font-weight': '700',
          'line-height': '1.3',
          'margin': '24px 0 10px 0',
        };
      case 'h3':
        return {
          'font-size': '1.18em',
          'font-weight': '600',
          'line-height': '1.35',
          'margin': '20px 0 8px 0',
        };
      case 'h4':
        return {
          'font-size': '1.06em',
          'font-weight': '600',
          'line-height': '1.35',
          'margin': '16px 0 6px 0',
        };
      case 'p':
        return {
          'margin': '0 0 14px 0',
        };
      case 'a':
        return {
          'color': _toCssHex(colorScheme.primary),
          'text-decoration': 'underline',
        };
      default:
        return null;
    }
  }

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color.fromARGB(255, 195, 195, 196),
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF1976D2),
      brightness: Brightness.light,
    ),
    cardTheme: CardThemeData(
      color: const Color.fromARGB(255, 235, 234, 234),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Color(0xFF1E1E1E),
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 1,
      shadowColor: Colors.black26,
      systemOverlayStyle: lightSystemOverlayStyle,
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF121212),
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF1976D2),
      brightness: Brightness.dark,
      surface: const Color(0xFF1E1E1E),
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF1E1E1E),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E1E1E),
      foregroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 1,
      shadowColor: Colors.black54,
      systemOverlayStyle: darkSystemOverlayStyle,
    ),
  );
}
