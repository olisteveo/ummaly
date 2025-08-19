import 'dart:convert';
import 'dart:io';

class HttpClientBinding {
  static Future<_HttpResponse> get(Uri uri, {Map<String, String>? headers}) async {
    final client = HttpClient();
    try {
      final req = await client.getUrl(uri);
      headers?.forEach(req.headers.add);
      final res = await req.close();
      final body = await res.transform(utf8.decoder).join();
      return _HttpResponse(res.statusCode, body);
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
