import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// Small GET helpers on dart:io, for the free music APIs the app uses.
class Web {
  static const _userAgent = 'Stash/0.1 (https://github.com/SalehTZ/Stash)';
  static const _timeout = Duration(seconds: 15);

  /// The response body, or null on a 404.
  static Future<Uint8List?> getBytes(Uri uri) async {
    final client = HttpClient()..connectionTimeout = _timeout;
    try {
      final request = await client.getUrl(uri).timeout(_timeout);
      request.headers.set(HttpHeaders.userAgentHeader, _userAgent);
      final response = await request.close().timeout(_timeout);
      if (response.statusCode == HttpStatus.notFound) return null;
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException('HTTP ${response.statusCode}', uri: uri);
      }
      final builder = BytesBuilder(copy: false);
      await response.timeout(_timeout).forEach(builder.add);
      return builder.takeBytes();
    } finally {
      client.close();
    }
  }

  /// The decoded JSON body, or null on a 404.
  static Future<Object?> getJson(Uri uri) async {
    final bytes = await getBytes(uri);
    return bytes == null ? null : jsonDecode(utf8.decode(bytes));
  }
}
