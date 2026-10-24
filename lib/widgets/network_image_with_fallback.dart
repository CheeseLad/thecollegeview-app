import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/image_proxy.dart';

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

  @override
  Widget build(BuildContext context) {
    final trimmedUrl = imageUrl.trim();

    if (trimmedUrl.isEmpty) {
      Widget fallback = _buildFallback(context);
      if (borderRadius != null) {
        return ClipRRect(
          borderRadius: borderRadius!,
          child: fallback,
        );
      }
      return fallback;
    }

    // Only use third-party proxy on Web where browser CORS may restrict direct requests.
    // On native mobile (Android/iOS), request directly from source.
    final effectiveUrl =
        kIsWeb ? ImageProxy.getProxiedImageUrl(trimmedUrl) : trimmedUrl;

    Widget imageWidget = CachedNetworkImage(
      imageUrl: effectiveUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: borderRadius,
        ),
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      errorWidget: (context, url, error) => _buildFallback(context),
    );

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }
}
