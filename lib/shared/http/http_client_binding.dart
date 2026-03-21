import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Cross-platform HTTP helper (works on web + mobile).
///
/// Uses `package:http` under the hood, which delegates to
/// `XMLHttpRequest` on web and `dart:io` on native.
class HttpClientBinding {
  /// Default network timeout for requests.
  static Duration defaultTimeout = const Duration(seconds: 20);

  static Future<_HttpResponse> get(
    Uri uri, {
    Map<String, String>? headers,
    Duration? timeout,
  }) {
    return _send(method: 'GET', uri: uri, headers: headers, timeout: timeout);
  }

  static Future<_HttpResponse> post(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
    Duration? timeout,
  }) {
    return _send(
      method: 'POST',
      uri: uri,
      headers: headers,
      body: body,
      timeout: timeout,
    );
  }

  static Future<_HttpResponse> put(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
    Duration? timeout,
  }) {
    return _send(
      method: 'PUT',
      uri: uri,
      headers: headers,
      body: body,
      timeout: timeout,
    );
  }

  static Future<_HttpResponse> delete(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
    Duration? timeout,
  }) {
    return _send(
      method: 'DELETE',
      uri: uri,
      headers: headers,
      body: body,
      timeout: timeout,
    );
  }

  static Future<_HttpResponse> _send({
    required String method,
    required Uri uri,
    Map<String, String>? headers,
    Object? body,
    Duration? timeout,
  }) async {
    try {
      final allHeaders = <String, String>{
        if (headers != null) ...headers,
      };

      // Default to JSON content type when sending a body
      if (body != null &&
          !allHeaders.keys.any((k) => k.toLowerCase() == 'content-type')) {
        allHeaders['Content-Type'] = 'application/json; charset=utf-8';
      }

      final encodedBody = body != null
          ? (body is String ? body : jsonEncode(body))
          : null;

      late http.Response res;

      switch (method) {
        case 'GET':
          res = await http.get(uri, headers: allHeaders)
              .timeout(timeout ?? defaultTimeout);
          break;
        case 'POST':
          res = await http.post(uri, headers: allHeaders, body: encodedBody)
              .timeout(timeout ?? defaultTimeout);
          break;
        case 'PUT':
          res = await http.put(uri, headers: allHeaders, body: encodedBody)
              .timeout(timeout ?? defaultTimeout);
          break;
        case 'DELETE':
          res = await http.delete(uri, headers: allHeaders, body: encodedBody)
              .timeout(timeout ?? defaultTimeout);
          break;
        default:
          return _HttpResponse(0, jsonEncode({
            'error': 'unsupported_method',
            'message': 'HTTP method $method is not supported',
          }));
      }

      return _HttpResponse(res.statusCode, res.body);
    } on TimeoutException {
      return _HttpResponse(0, jsonEncode({
        'error': 'timeout',
        'message': 'Request timed out',
      }));
    } catch (e) {
      return _HttpResponse(0, jsonEncode({
        'error': 'network_error',
        'message': e.toString(),
      }));
    }
  }
}

class _HttpResponse {
  final int statusCode;
  final String body;
  _HttpResponse(this.statusCode, this.body);
}
