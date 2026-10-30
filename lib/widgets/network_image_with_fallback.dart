import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'skeleton.dart';
import '../config/app_config.dart';

class NetworkImageWithFallback extends StatelessWidget {
  static final Set<String> _preloadedKeys = {};

  final String imageUrl;
  final String fallbackAssetPath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const NetworkImageWithFallback({
    super.key,
    required this.imageUrl,
    required this.fallbackAssetPath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  static String _normalizeImageUrl(String rawUrl) {
    final trimmed = rawUrl.trim();
    if (trimmed.startsWith('http://')) {
      return 'https://${trimmed.substring(7)}';
    }
    return trimmed;
  }

  static String _proxiedImageUrl(String originalUrl) {
    if (originalUrl.isEmpty || originalUrl.contains('weserv.nl')) {
      return originalUrl;
    }
    final encodedUrl = Uri.encodeComponent(originalUrl);
    return '${AppConfig.instance.imageProxyUrl}$encodedUrl';
  }

  static String _cacheKey(String trimmedUrl, int? targetCacheWidth) =>
      '$trimmedUrl@${targetCacheWidth ?? 0}';

  static bool isPreloaded(
    BuildContext context,
    String imageUrl, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
  }) {
    final trimmedUrl = _normalizeImageUrl(imageUrl);
    if (trimmedUrl.isEmpty) return true;
    final targetCacheWidth = resolveTargetCacheWidth(
      context,
      width: width,
      height: height,
      fit: fit,
    );
    return _preloadedKeys.contains(_cacheKey(trimmedUrl, targetCacheWidth));
  }

  /// Preloads and decodes the image into Flutter's [ImageCache] so that when
  /// the skeleton screen transitions to content, the image renders immediately.
  static Future<void> preload(
    BuildContext context,
    String imageUrl, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
  }) async {
    final trimmedUrl = _normalizeImageUrl(imageUrl);
    if (trimmedUrl.isEmpty) return;

    final effectiveUrl = kIsWeb ? _proxiedImageUrl(trimmedUrl) : trimmedUrl;
    final targetCacheWidth = resolveTargetCacheWidth(
      context,
      width: width,
      height: height,
      fit: fit,
    );
    final key = _cacheKey(trimmedUrl, targetCacheWidth);
    if (_preloadedKeys.contains(key)) return;

    if (kIsWeb && AppConfig.instance.forceOfflineMode) {
      _preloadedKeys.add(key);
      return;
    }

    final ImageProvider baseProvider = kIsWeb
        ? NetworkImage(effectiveUrl)
        : CachedNetworkImageProvider(effectiveUrl);
    final ImageProvider provider = ResizeImage.resizeIfNeeded(
      targetCacheWidth,
      null,
      baseProvider,
    );

    final timeout = AppConfig.instance.forceOfflineMode
        ? const Duration(milliseconds: 400)
        : const Duration(seconds: 6);

    try {
      await precacheImage(
        provider,
        context,
        onError: (_, __) {},
      ).timeout(timeout);
    } catch (_) {
      // Fall back gracefully if the image fails or times out.
    } finally {
      _preloadedKeys.add(key);
    }
  }

  /// Computes a target decode width in physical pixels to avoid decoding
  /// full-resolution images for small thumbnails or constrained headers,
  /// while preserving aspect ratio (by only constraining width).
  static int? resolveTargetCacheWidth(
    BuildContext context, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    bool isAsset = false,
  }) {
    final dpr = MediaQuery.devicePixelRatioOf(context).clamp(1.0, 3.5);
    final hasFiniteWidth = width != null && width.isFinite && width > 0;
    final hasFiniteHeight = height != null && height.isFinite && height > 0;

    if (hasFiniteWidth && hasFiniteHeight) {
      final base = math.max(width, height);
      // For BoxFit.cover on landscape photos inside square thumbnails,
      // allow 1.8x headroom so the shorter axis stays crisp after cropping.
      final multiplier = (!isAsset && fit == BoxFit.cover) ? 1.8 : 1.0;
      return (base * multiplier * dpr).round();
    }

    if (hasFiniteWidth) {
      return (width * dpr).round();
    }

    if (width == double.infinity && hasFiniteHeight) {
      final screenWidth = MediaQuery.sizeOf(context).width.clamp(100.0, 900.0);
      final targetLogicalWidth = math.max(screenWidth, height * 1.8);
      return (targetLogicalWidth * dpr).round();
    }

    if (hasFiniteHeight) {
      return (height * (isAsset ? 1.0 : 1.8) * dpr).round();
    }

    return null;
  }

  int? _resolveTargetCacheWidth(BuildContext context, {bool isAsset = false}) =>
      resolveTargetCacheWidth(
        context,
        width: width,
        height: height,
        fit: fit,
        isAsset: isAsset,
      );

  Widget _buildFallback(BuildContext context) {
    final assetCacheWidth = _resolveTargetCacheWidth(context, isAsset: true);
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: borderRadius,
      ),
      child: Image.asset(
        fallbackAssetPath,
        width: width,
        height: height,
        fit: fit,
        cacheWidth: assetCacheWidth,
        filterQuality: FilterQuality.low,
        errorBuilder: (context, error, stackTrace) {
          return Icon(
            Icons.image_not_supported,
            color: Theme.of(context).disabledColor,
            size: 36,
          );
        },
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return SkeletonBox(
      width: width,
      height: height,
      borderRadius: borderRadius,
    );
  }

  @override
  Widget build(BuildContext context) {
    final trimmedUrl = _normalizeImageUrl(imageUrl);

    if (trimmedUrl.isEmpty || (kIsWeb && AppConfig.instance.forceOfflineMode)) {
      Widget fallback = _buildFallback(context);
      if (borderRadius != null) {
        fallback = ClipRRect(
          borderRadius: borderRadius!,
          child: fallback,
        );
      }
      return RepaintBoundary(child: fallback);
    }

    // Only use third-party proxy on Web where browser CORS may restrict direct requests.
    // On native mobile (Android/iOS), request directly from source.
    final effectiveUrl = kIsWeb ? _proxiedImageUrl(trimmedUrl) : trimmedUrl;
    final targetCacheWidth = _resolveTargetCacheWidth(context);

    Widget imageWidget;
    if (kIsWeb) {
      imageWidget = Image.network(
        effectiveUrl,
        width: width,
        height: height,
        fit: fit,
        cacheWidth: targetCacheWidth,
        filterQuality: FilterQuality.low,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildPlaceholder(context);
        },
        errorBuilder: (context, error, stackTrace) => _buildFallback(context),
      );
    } else {
      imageWidget = CachedNetworkImage(
        imageUrl: effectiveUrl,
        width: width,
        height: height,
        fit: fit,
        memCacheWidth: targetCacheWidth,
        filterQuality: FilterQuality.low,
        fadeInDuration: Duration.zero,
        fadeOutDuration: Duration.zero,
        useOldImageOnUrlChange: true,
        placeholder: (context, url) => _buildPlaceholder(context),
        errorWidget: (context, url, error) => _buildFallback(context),
      );
    }

    if (borderRadius != null) {
      imageWidget = ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return RepaintBoundary(child: imageWidget);
  }
}
