import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'skeleton.dart';
import '../config/app_config.dart';

class NetworkImageWithFallback extends StatelessWidget {
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

  static String _proxiedImageUrl(String originalUrl) {
    if (originalUrl.isEmpty || originalUrl.contains('weserv.nl')) {
      return originalUrl;
    }
    final encodedUrl = Uri.encodeComponent(originalUrl);
    return '${AppConfig.instance.imageProxyUrl}$encodedUrl';
  }

  Widget _buildFallback(BuildContext context) {
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
    final trimmedUrl = imageUrl.trim();

    if (trimmedUrl.isEmpty) {
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

    Widget imageWidget;
    if (kIsWeb) {
      imageWidget = Image.network(
        effectiveUrl,
        width: width,
        height: height,
        fit: fit,
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
