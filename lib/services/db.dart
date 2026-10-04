import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

class DbException implements Exception {
  DbException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;
  @override
  String toString() => message;
}

/// Minimal Firebase Realtime Database REST client (the App Inventor app used
/// the same REST endpoints through its Web component).
class Db {
  Db._();
  static final Db instance = Db._();
  final http.Client _client = http.Client();

  Uri _uri(String path, {bool shallow = false}) {
    final clean = path.replaceAll(RegExp(r'^/+|/+$'), '');
    final params = <String, String>{
      if (shallow) 'shallow': 'true',
      if (AppConfig.authToken.isNotEmpty) 'auth': AppConfig.authToken,
    };
    return Uri.parse('${AppConfig.databaseUrl}/$clean.json')
        .replace(queryParameters: params.isEmpty ? null : params);
  }

  Future<dynamic> _send(Future<http.Response> Function() call) async {
    try {
      final res = await call().timeout(AppConfig.timeout);
      final body = utf8.decode(res.bodyBytes);
      if (res.statusCode < 200 || res.statusCode >= 300) {
        var msg = 'Database error (${res.statusCode})';
        try {
          final d = jsonDecode(body);
          if (d is Map && d['error'] != null) msg = '${d['error']}';
        } catch (_) {}
        throw DbException(msg, statusCode: res.statusCode);
      }
      return body.isEmpty ? null : jsonDecode(body);
    } on DbException {
      rethrow;
    } on TimeoutException {
      throw DbException('The connection timed out. Please try again.');
    } catch (_) {
      throw DbException(
          'Could not reach the database. Check your internet connection.');
    }
  }

  Future<dynamic> get(String path, {bool shallow = false}) =>
      _send(() => _client.get(_uri(path, shallow: shallow)));

  Future<void> put(String path, Object? value) => _send(() => _client.put(
      _uri(path),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(value)));

  /// PATCH merges the given keys. Use '' as the path with slash-separated keys
  /// to update several locations in one atomic write.
  Future<void> patch(String path, Map<String, dynamic> value) =>
      _send(() => _client.patch(_uri(path),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(value)));
}

/// Firebase stores keys 1..n as a JSON array with `null` in slot 0.
/// This returns (key, value) pairs for both arrays and objects, skipping nulls,
/// ordered by numeric key where possible.
List<MapEntry<String, dynamic>> entriesOf(dynamic node) {
  final out = <MapEntry<String, dynamic>>[];
  if (node is List) {
    for (var i = 0; i < node.length; i++) {
      if (node[i] != null) out.add(MapEntry('$i', node[i]));
    }
  } else if (node is Map) {
    node.forEach((k, v) {
      if (v != null) out.add(MapEntry('$k', v));
    });
    out.sort((a, b) {
      final x = int.tryParse(a.key), y = int.tryParse(b.key);
      if (x != null && y != null) return x.compareTo(y);
      return a.key.compareTo(b.key);
    });
  }
  return out;
}

int asInt(dynamic v) => v is num ? v.toInt() : int.tryParse('${v ?? ''}') ?? 0;
