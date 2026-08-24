class ImageProxy {
  static const String _proxyUrl = 'https://images.weserv.nl/?url=';
  
  static String getProxiedImageUrl(String originalUrl) {
    if (originalUrl.isEmpty) return originalUrl;
    
    if (originalUrl.contains('weserv.nl')) {
      return originalUrl;
    }
    
    final encodedUrl = Uri.encodeComponent(originalUrl);
    return '$_proxyUrl$encodedUrl';
  }
}
