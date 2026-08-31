import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    // Use the image proxy to handle CORS issues
    final proxiedImageUrl = ImageProxy.getProxiedImageUrl(imageUrl);
    
    Widget imageWidget = Image.network(
      proxiedImageUrl,
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: borderRadius,
          ),
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        // Log the error for debugging (CORS issues, network problems, etc.)
        print('Image load error: $error');
        
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
              // If even the fallback asset fails, show a placeholder icon
               return Container(
                 width: width,
                 height: height,
                 decoration: BoxDecoration(
                   color: Theme.of(context).colorScheme.surfaceContainerHighest,
                   borderRadius: borderRadius,
                 ),
                child: Icon(
                  Icons.image_not_supported,
                  color: Theme.of(context).disabledColor,
                  size: 48,
                ),
              );
            },
          ),
        );
      },
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
