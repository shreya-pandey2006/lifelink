import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../core/config.dart';

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
  VoidCallback? onUnauthorized; // called when the server says 401

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
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

  Future<dynamic> _send(String method, String path,
      [Map<String, dynamic>? body]) async {
    final uri = Uri.parse('$kBaseUrl$path');
    final encoded = body == null ? null : jsonEncode(body);

    try {
      final res = await _request(method, uri, encoded)
          .timeout(const Duration(seconds: 15));
      final data = res.body.isEmpty ? null : jsonDecode(res.body);

      if (res.statusCode >= 200 && res.statusCode < 300) return data;

      if (res.statusCode == 401 && token != null) onUnauthorized?.call();
      final msg = (data is Map && data['message'] != null)
          ? data['message'].toString()
          : 'Request failed (${res.statusCode})';
      throw ApiException(msg, res.statusCode);
    } on SocketException {
      throw ApiException(
          'Cannot reach the server. Check your internet and the server address.');
    } on http.ClientException {
      throw ApiException(
          'Cannot reach the server. Check your internet and the server address.');
    } on TimeoutException {
      throw ApiException('The server took too long to respond. Try again.');
    } on FormatException {
      throw ApiException('The server sent an unexpected response.');
    }
  }
}