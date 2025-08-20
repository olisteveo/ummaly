import 'dart:async'; // <-- Needed for TimeoutException
import 'dart:convert';
import 'dart:io';

class HttpClientBinding {
  /// Default network timeout for requests.
  static Duration defaultTimeout = const Duration(seconds: 20);

  static Future<_HttpResponse> get(
      Uri uri, {
        Map<String, String>? headers,
        Duration? timeout,
      }) {
    return _send(
      method: 'GET',
      uri: uri,
      headers: headers,
      timeout: timeout,
    );
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
        Object? body, // Some APIs accept a body with DELETE
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

  /// Internal helper to open/send any HTTP method with optional JSON body.
  static Future<_HttpResponse> _send({
    required String method,
    required Uri uri,
    Map<String, String>? headers,
    Object? body,
    Duration? timeout,
  }) async {
    final client = HttpClient();
    try {
      final req = await client.openUrl(method, uri);

      // Apply headers first
      headers?.forEach(req.headers.add);

      // If there is a body and no explicit content-type was provided,
      // default to JSON (common case in this app).
      if (body != null &&
          !(headers?.keys.any((k) => k.toLowerCase() == 'content-type') ??
              false)) {
        req.headers.set(
          HttpHeaders.contentTypeHeader,
          'application/json; charset=utf-8',
        );
      }

      // Write body (String is written as-is; anything else JSON-encoded)
      if (body != null) {
        if (body is String) {
          req.write(body);
        } else {
          req.write(jsonEncode(body));
        }
      }

      // Send and collect response (with optional timeout)
      final res = await req.close().timeout(timeout ?? defaultTimeout);
      final resBody = await res.transform(utf8.decoder).join();

      return _HttpResponse(res.statusCode, resBody);
    } on SocketException catch (e) {
      // Surface a network-y error in a consistent shape
      return _HttpResponse(
        0,
        jsonEncode({
          'error': 'network_error',
          'message': e.message,
        }),
      );
    } on TimeoutException {
      return _HttpResponse(
        0,
        jsonEncode({
          'error': 'timeout',
          'message': 'Request timed out',
        }),
      );
    } finally {
      client.close(force: true);
    }
  }
}

class _HttpResponse {
  final int statusCode;
  final String body;
  _HttpResponse(this.statusCode, this.body);
}
