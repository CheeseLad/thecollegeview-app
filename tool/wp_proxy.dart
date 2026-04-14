import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

const String wpHost = 'thecollegeview.ie';
const String usernameKey = 'WP_API_USERNAME';
const String passwordKey = 'WP_API_PASSWORD';

Future<void> main(List<String> args) async {
  final port = _readPort(args);
  final config = _loadConfig();

  final username = config[usernameKey] ?? '';
  final password = config[passwordKey] ?? '';

  if (username.isEmpty || password.isEmpty) {
    stderr.writeln('Missing WP_API_USERNAME/WP_API_PASSWORD in environment or .env file.');
    exitCode = 1;
    return;
  }

  final authToken = base64Encode(utf8.encode('$username:$password'));
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
  stdout.writeln('WP proxy listening at http://127.0.0.1:$port');
  stdout.writeln('Forwarding /wp-json/* to https://$wpHost with Basic auth.');

  await for (final request in server) {
    _setCorsHeaders(request.response);

    if (request.method == 'OPTIONS') {
      request.response.statusCode = HttpStatus.ok;
      await request.response.close();
      continue;
    }

    if (request.method != 'GET') {
      request.response.statusCode = HttpStatus.methodNotAllowed;
      request.response.write('Only GET is supported by this proxy.');
      await request.response.close();
      continue;
    }

    if (!request.uri.path.startsWith('/wp-json/')) {
      request.response.statusCode = HttpStatus.notFound;
      request.response.write('Use /wp-json/... paths.');
      await request.response.close();
      continue;
    }

    final targetUri = Uri.https(wpHost, request.uri.path, request.uri.queryParametersAll);

    try {
      final upstream = await http.get(
        targetUri,
        headers: {'Authorization': 'Basic $authToken'},
      );

      request.response.statusCode = upstream.statusCode;
      final contentType = upstream.headers['content-type'];
      if (contentType != null && contentType.isNotEmpty) {
        request.response.headers.set(HttpHeaders.contentTypeHeader, contentType);
      }
      request.response.write(upstream.body);
    } catch (_) {
      request.response.statusCode = HttpStatus.badGateway;
      request.response.write('Proxy request failed.');
    }

    await request.response.close();
  }
}

int _readPort(List<String> args) {
  for (final arg in args) {
    if (arg.startsWith('--port=')) {
      final value = int.tryParse(arg.substring('--port='.length));
      if (value != null) {
        return value;
      }
    }
  }
  return 8787;
}

Map<String, String> _loadConfig() {
  final result = <String, String>{};

  final envUser = Platform.environment[usernameKey];
  final envPass = Platform.environment[passwordKey];
  if (envUser != null && envUser.isNotEmpty) {
    result[usernameKey] = envUser;
  }
  if (envPass != null && envPass.isNotEmpty) {
    result[passwordKey] = envPass;
  }

  final file = File('.env');
  if (!file.existsSync()) {
    return result;
  }

  for (final line in file.readAsLinesSync()) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.startsWith('#') || !trimmed.contains('=')) {
      continue;
    }

    final idx = trimmed.indexOf('=');
    final key = trimmed.substring(0, idx).trim();
    var value = trimmed.substring(idx + 1).trim();

    if (value.length >= 2 && value.startsWith('"') && value.endsWith('"')) {
      value = value.substring(1, value.length - 1);
    }

    if ((key == usernameKey || key == passwordKey) && value.isNotEmpty) {
      result[key] = value;
    }
  }

  return result;
}

void _setCorsHeaders(HttpResponse response) {
  response.headers.set(HttpHeaders.accessControlAllowOriginHeader, '*');
  response.headers.set(HttpHeaders.accessControlAllowMethodsHeader, 'GET, OPTIONS');
  response.headers.set(HttpHeaders.accessControlAllowHeadersHeader, 'Content-Type, Authorization');
}
