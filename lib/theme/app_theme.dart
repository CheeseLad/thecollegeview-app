import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _boxName = 'settings';
  static const String _themeKey = 'themeMode';
  ThemeMode _themeMode = ThemeMode.system;
  Box? _box;

  ThemeMode get themeMode => _themeMode;

  Future<void> init() async {
    try {
      _box = await Hive.openBox(_boxName);
      final savedMode = _box?.get(_themeKey) as String?;
      if (savedMode == 'light') {
        _themeMode = ThemeMode.light;
      } else if (savedMode == 'dark') {
        _themeMode = ThemeMode.dark;
      } else {
        _themeMode = ThemeMode.system;
      }
    } catch (_) {
      _themeMode = ThemeMode.system;
    }
    notifyListeners();
  }

  bool get isDark {
    if (_themeMode == ThemeMode.light) return false;
    if (_themeMode == ThemeMode.dark) return true;
    return WidgetsBinding.instance.platformDispatcher.platformBrightness ==
        Brightness.dark;
  }

  String get themeModeLabel {
    switch (_themeMode) {
      case ThemeMode.system:
        return 'System';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
    }
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    _saveThemeMode(mode);
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
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF7F8FA),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF1976D2),
        brightness: Brightness.light,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
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
