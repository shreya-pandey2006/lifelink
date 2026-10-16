import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/config.dart';
import 'mock_api.dart';
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, [this.statusCode]);
  @override
  String toString() => message;
}

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();
  String? token;
  VoidCallback? onUnauthorized;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Future<dynamic> get(String path) => _send('GET', path);
  Future<dynamic> post(String path, [Map<String, dynamic>? body]) =>
      _send('POST', path, body);
  Future<dynamic> put(String path, [Map<String, dynamic>? body]) =>
      _send('PUT', path, body);
  Future<dynamic> patch(String path, [Map<String, dynamic>? body]) =>
      _send('PATCH', path, body);

  Future<http.Response> _request(String method, Uri uri, String? body) {
    switch (method) {
      case 'POST':
        return http.post(uri, headers: _headers, body: body);
      case 'PUT':
        return http.put(uri, headers: _headers, body: body);
      case 'PATCH':
        return http.patch(uri, headers: _headers, body: body);
      default:
        return http.get(uri, headers: _headers);
    }
  }

  String _errorMessage(dynamic data, int status) {
    if (data is Map) {
      final m = data['message'] ?? data['error'];
      if (m != null) return m.toString();
      final errs = data['errors'];
      if (errs is List && errs.isNotEmpty) {
        final first = errs.first;
        if (first is Map && first['msg'] != null) return first['msg'].toString();
        return first.toString();
      }
    }
    if (status == 403) return "You don't have permission to do this.";
    return 'Request failed ($status)';
  }

  Future<dynamic> _send(String method, String path,
      [Map<String, dynamic>? body]) async {
    if (kUseMockApi) {
      return MockApi.instance.handle(method, path, body, token);
    }
    final cleanBase = kBaseUrl.endsWith('/')
        ? kBaseUrl.substring(0, kBaseUrl.length - 1)
        : kBaseUrl;
    final cleanPath = path.startsWith('/') ? path : '/$path';
    final uri = Uri.parse('$cleanBase$cleanPath');
    final encoded = body == null ? null : jsonEncode(body);
    try {
      final res = await _request(method, uri, encoded)
          .timeout(const Duration(seconds: 60));
      if (kDebugMode) {
        debugPrint('[API] $method $path -> ${res.statusCode}\n${res.body}');
      }
      dynamic data;
      if (res.body.isNotEmpty) {
        try {
          data = jsonDecode(res.body);
        } on FormatException {
          if (res.statusCode >= 200 && res.statusCode < 300) {
            throw ApiException('The server sent an unexpected response.');
          }
        }
      }
      if (res.statusCode >= 200 && res.statusCode < 300) return data;
      if (res.statusCode == 401 && token != null) onUnauthorized?.call();
      throw ApiException(_errorMessage(data, res.statusCode), res.statusCode);
    } on SocketException {
      throw ApiException('Cannot reach the server. Check your internet connection.');
    } on http.ClientException {
      throw ApiException('Cannot reach the server. Check your internet connection.');
    } on TimeoutException {
      throw ApiException('The server is waking up. Please try again in a moment.');
    }
  }
}