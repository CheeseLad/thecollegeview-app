import 'package:flutter/material.dart';
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

  static Color articleDetailBackgroundColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkArticleDetailBackgroundColor
        : lightArticleDetailBackgroundColor;
  }

  static ThemeData get lightTheme {
    return ThemeData(
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
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
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
      ),
    );
  }
}
