import 'package:flutter/foundation.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';

/// Utility class for configuring and maintaining high refresh rate support across platforms.
class DisplayUtils {
  const DisplayUtils._();

  /// Requests the highest available refresh rate on supported platforms (e.g. 90Hz, 120Hz, 144Hz).
  ///
  /// - On Android, sets the display mode with the highest refresh rate via `FlutterDisplayMode`.
  /// - On iOS, high refresh rate (ProMotion) is enabled via `CADisableMinimumFrameDurationOnPhone` in Info.plist.
  /// - On Web and desktop, refresh rate is tied to the display's native vsync refresh rate.
  static Future<void> enableHighRefreshRate() async {
    if (kIsWeb) return;

    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        await FlutterDisplayMode.setHighRefreshRate();
      } catch (e) {
        debugPrint('DisplayUtils: Failed to set high refresh rate: $e');
      }
    }
  }

  /// Returns the current active refresh rate in Hz, or null if unsupported or unavailable.
  static Future<double?> getActiveRefreshRate() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return null;
    }
    try {
      final mode = await FlutterDisplayMode.active;
      return mode.refreshRate;
    } catch (e) {
      debugPrint('DisplayUtils: Failed to get active refresh rate: $e');
      return null;
    }
  }

  /// Returns the highest supported refresh rate in Hz, or null if unsupported or unavailable.
  static Future<double?> getHighestRefreshRate() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return null;
    }
    try {
      final modes = await FlutterDisplayMode.supported;
      if (modes.isEmpty) return null;
      double maxRate = 0;
      for (final mode in modes) {
        if (mode.refreshRate > maxRate) {
          maxRate = mode.refreshRate;
        }
      }
      return maxRate > 0 ? maxRate : null;
    } catch (e) {
      debugPrint('DisplayUtils: Failed to get highest refresh rate: $e');
      return null;
    }
  }
}

