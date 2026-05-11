import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

import 'api_exception.dart';

class ApiClient {
  ApiClient({required String baseUrl})
      : _baseUrl = baseUrl.replaceFirst(RegExp(r'/$'), '');

  final String _baseUrl;
  String? _token;

  void setToken(String? token) {
    _token = token;
  }

  Future<dynamic> delete(String path) async {
    try {
      final response = await http.delete(_uri(path), headers: _headers());
      return _decode(response);
    } catch (error) {
      throw _wrapTransportError(error);
    }
  }

  Future<dynamic> get(String path) async {
    try {
      final response = await http.get(_uri(path), headers: _headers());
      return _decode(response);
    } catch (error) {
      throw _wrapTransportError(error);
    }
  }

  Future<dynamic> patch(String path, {Object? body}) async {
    try {
      final response = await http.patch(
        _uri(path),
        headers: _headers(jsonBody: body != null),
        body: body == null ? null : jsonEncode(body),
      );
      return _decode(response);
    } catch (error) {
      throw _wrapTransportError(error);
    }
  }

  Future<dynamic> post(String path, {Object? body}) async {
    try {
      final response = await http.post(
        _uri(path),
        headers: _headers(jsonBody: body != null),
        body: body == null ? null : jsonEncode(body),
      );
      return _decode(response);
    } catch (error) {
      throw _wrapTransportError(error);
    }
  }

  Future<dynamic> multipart(
    String method,
    String path, {
    Map<String, String> fields = const {},
    List<MultipartFilePart> files = const [],
  }) async {
    final request = http.MultipartRequest(method, _uri(path));

    if (_token != null && _token!.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $_token';
    }

    request.fields.addAll(fields);

    for (final file in files) {
      if (file.path.isEmpty) {
        continue;
      }

      request.files.add(
        await http.MultipartFile.fromPath(
          file.field,
          file.path,
          filename: file.filename,
          contentType: _multipartContentType(file),
        ),
      );
    }

    try {
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      return _decode(response);
    } catch (error) {
      throw _wrapTransportError(error);
    }
  }

  String resolveUrl(String path) {
    if (path.isEmpty || path.startsWith('http') || path.startsWith('data:')) {
      return path;
    }

    if (path.startsWith('/')) {
      return '$_baseUrl$path';
    }

    return '$_baseUrl/$path';
  }

  dynamic _decode(http.Response response) {
    final payload =
        jsonDecode(response.body.isEmpty ? '{}' : response.body) as Object?;
    final body =
        payload is Map ? payload.cast<String, dynamic>() : <String, dynamic>{};

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        body['message']?.toString() ?? 'Request failed',
        statusCode: response.statusCode,
      );
    }

    return body.containsKey('data') ? body['data'] : body;
  }

  Map<String, String> _headers({bool jsonBody = false}) {
    final headers = <String, String>{};

    if (_token != null && _token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_token';
    }

    if (jsonBody) {
      headers['Content-Type'] = 'application/json';
    }

    return headers;
  }

  Uri _uri(String path) {
    final cleanPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$_baseUrl$cleanPath');
  }

  MediaType? _multipartContentType(MultipartFilePart file) {
    final reference = file.filename?.trim().isNotEmpty == true
        ? file.filename!.trim()
        : file.path.trim();
    final mimeType = lookupMimeType(reference);

    if (mimeType == null || !mimeType.contains('/')) {
      return null;
    }

    return MediaType.parse(mimeType);
  }

  ApiException _wrapTransportError(Object error) {
    final message = error.toString();

    if (message.contains('Failed host lookup')) {
      return ApiException(
        'Network error: could not resolve $_baseUrl. Check phone internet or use local backend via adb reverse.',
      );
    }

    if (message.contains('Connection refused') ||
        message.contains('Connection reset') ||
        message.contains('Connection closed')) {
      return ApiException(
        'Network error: could not reach $_baseUrl. Make sure the backend is running and reachable.',
      );
    }

    if (message.toLowerCase().contains('timed out')) {
      return ApiException(
        'Network timeout while connecting to $_baseUrl. Check that the backend URL is correct and the server is reachable.',
      );
    }

    if (error is ApiException) {
      return error;
    }

    return ApiException(message.replaceFirst('Exception: ', ''));
  }
}

class MultipartFilePart {
  const MultipartFilePart({
    required this.field,
    required this.path,
    this.filename,
  });

  final String field;
  final String path;
  final String? filename;
}
