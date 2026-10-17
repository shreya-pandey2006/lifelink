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
  http.Client client = http.Client();
  String? token;
  VoidCallback? onUnauthorized;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Future<dynamic> get(String path, {Map<String, dynamic>? queryParameters}) =>
      _send('GET', path, null, queryParameters);
  Future<dynamic> post(String path, [Map<String, dynamic>? body]) =>
      _send('POST', path, body);
  Future<dynamic> put(String path, [Map<String, dynamic>? body]) =>
      _send('PUT', path, body);
  Future<dynamic> patch(String path, [Map<String, dynamic>? body]) =>
      _send('PATCH', path, body);
  Future<dynamic> delete(String path, [Map<String, dynamic>? body]) =>
      _send('DELETE', path, body);

  Future<http.Response> _request(String method, Uri uri, String? body) {
    switch (method) {
      case 'POST':
        return client.post(uri, headers: _headers, body: body);
      case 'PUT':
        return client.put(uri, headers: _headers, body: body);
      case 'PATCH':
        return client.patch(uri, headers: _headers, body: body);
      case 'DELETE':
        return client.delete(uri, headers: _headers, body: body);
      default:
        return client.get(uri, headers: _headers);
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
    if (status == 502) return "The upstream service is temporarily unavailable. Please try again.";
    return 'Request failed ($status)';
  }

  Future<dynamic> _send(String method, String path,
      [Map<String, dynamic>? body,
      Map<String, dynamic>? queryParameters]) async {
    if (kUseMockApi) {
      return MockApi.instance.handle(method, path, body, token);
    }
    final cleanBase = kBaseUrl.endsWith('/')
        ? kBaseUrl.substring(0, kBaseUrl.length - 1)
        : kBaseUrl;
    var cleanPath = path.startsWith('/') ? path : '/$path';
    if (cleanBase.endsWith('/api') && cleanPath.startsWith('/api/')) {
      cleanPath = cleanPath.substring(4);
    }
    var uri = Uri.parse('$cleanBase$cleanPath');
    if (queryParameters != null && queryParameters.isNotEmpty) {
      final query = Map<String, dynamic>.from(uri.queryParameters);
      queryParameters.forEach((k, v) {
        if (v != null) query[k] = v.toString();
      });
      uri = uri.replace(queryParameters: query);
    }
    final encoded = body == null ? null : jsonEncode(body);
    int attempts = 0;
    while (attempts < 2) {
      attempts++;
      try {
        final res = await _request(method, uri, encoded)
            .timeout(const Duration(seconds: 45));
        if (kDebugMode) {
          debugPrint('[API] $method $path -> ${res.statusCode}\n${res.body}');
        }
        if ((res.statusCode == 502 ||
                res.statusCode == 503 ||
                res.statusCode == 504) &&
            attempts < 2) {
          await Future.delayed(const Duration(milliseconds: 1500));
          continue;
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
        if (attempts < 2) {
          await Future.delayed(const Duration(milliseconds: 1500));
          continue;
        }
        throw ApiException(
            'Cannot reach the server. Check your internet connection.');
      } on http.ClientException {
        if (attempts < 2) {
          await Future.delayed(const Duration(milliseconds: 1500));
          continue;
        }
        throw ApiException(
            'Cannot reach the server. Check your internet connection.');
      } on TimeoutException {
        if (attempts < 2) {
          await Future.delayed(const Duration(milliseconds: 1500));
          continue;
        }
        throw ApiException(
            'The server is waking up. Please try again in a moment.');
      }
    }
  }
}