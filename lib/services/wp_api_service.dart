import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class WpApiService {
  static const String _host = 'thecollegeview.ie';
  static const String _usernameKey = 'WP_API_USERNAME';
  static const String _passwordKey = 'WP_API_PASSWORD';
  static const String _proxyBaseUrlKey = 'WP_API_PROXY_BASE_URL';

  static Future<http.Response> get(Uri uri, {Map<String, String>? headers}) {
    if (kIsWeb && uri.host == _host && uri.path.startsWith('/wp-json/')) {
      final proxyUri = _buildProxyUri(uri);
      if (proxyUri != null) {
        return http.get(proxyUri, headers: headers);
      }
    }

    final mergedHeaders = <String, String>{...?headers, ..._authHeadersFor(uri)};
    return http.get(uri, headers: mergedHeaders.isEmpty ? null : mergedHeaders);
  }

  static Uri? _buildProxyUri(Uri originalUri) {
    final proxyBase = _readConfig(_proxyBaseUrlKey, const String.fromEnvironment(_proxyBaseUrlKey));
    if (proxyBase.isEmpty) {
      return null;
    }

    final parsedBase = Uri.tryParse(proxyBase);
    if (parsedBase == null || !parsedBase.hasScheme || parsedBase.host.isEmpty) {
      return null;
    }

    final basePath = parsedBase.path.endsWith('/')
        ? parsedBase.path.substring(0, parsedBase.path.length - 1)
        : parsedBase.path;
    final path = originalUri.path.startsWith('/') ? originalUri.path : '/${originalUri.path}';

    return parsedBase.replace(
      path: '$basePath$path',
      query: originalUri.query,
    );
  }

  static Map<String, String> _authHeadersFor(Uri uri) {
    if (uri.host != _host || !uri.path.startsWith('/wp-json/')) {
      return const {};
    }

    final username = _readConfig(_usernameKey, const String.fromEnvironment(_usernameKey));
    final password = _readConfig(_passwordKey, const String.fromEnvironment(_passwordKey));

    if (username.isEmpty || password.isEmpty) {
      return const {};
    }

    final token = base64Encode(utf8.encode('$username:$password'));
    return {'Authorization': 'Basic $token'};
  }

  static String _readConfig(String key, String fallback) {
    final envValue = dotenv.env[key];
    if (envValue != null && envValue.isNotEmpty) {
      return envValue;
    }
    return fallback;
  }
}