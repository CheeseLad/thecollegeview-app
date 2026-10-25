import '../config/app_config.dart';

class ImageProxy {
  static String get _proxyUrl => AppConfig.instance.imageProxyUrl;

  static String getProxiedImageUrl(String originalUrl) {
    if (originalUrl.isEmpty) return originalUrl;

    if (originalUrl.contains('weserv.nl')) {
      return originalUrl;
    }

    final encodedUrl = Uri.encodeComponent(originalUrl);
    return '$_proxyUrl$encodedUrl';
  }
}
