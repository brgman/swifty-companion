import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

class ApiClient {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _expiresAtKey = 'expires_at';

  final String clientId;
  final String clientSecret;

  ApiClient({required this.clientId, required this.clientSecret});

  Future<String?> _getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }

  Future<bool> _refreshIfNeeded() async {
    final now = DateTime.now();

    final prefs = await SharedPreferences.getInstance();
    final currentToken = await _getAccessToken();
    final expiresAt = prefs.getInt(_expiresAtKey) ?? 0;
    final expiresAtDate = DateTime.fromMillisecondsSinceEpoch(expiresAt);
    final timeNow = DateTime.now().millisecondsSinceEpoch;
    final intervalForUpdate = 8000000; // ms
    final diffMinutes = expiresAtDate.difference(now).inMinutes;
     final updateAtDate = DateTime.fromMillisecondsSinceEpoch(expiresAt - intervalForUpdate);

    debugPrint("refreshIfNeeded: current token: ${currentToken}");
    debugPrint("refreshIfNeeded: time now: ${DateFormat('dd MMMM yyyy HH:mm:ss.SSS').format(now)}");
    debugPrint("refreshIfNeeded: expires at: ${DateFormat('dd MMMM yyyy HH:mm:ss.SSS').format(expiresAtDate)}");
    debugPrint("refreshIfNeeded: update at: ${DateFormat('dd MMMM yyyy HH:mm:ss.SSS').format(updateAtDate)}");
    debugPrint("refreshIfNeeded: real diff (mins): ${diffMinutes}");

    // OK
    if (timeNow <= expiresAt - intervalForUpdate) {
      debugPrint("OK: TOKEN IS VALID");
      return true;
    }

    // UPDATE
    final refreshToken = prefs.getString(_refreshTokenKey);
    if (refreshToken == null) return false;

    try {
      final res = await http.post(
        Uri.parse('https://api.intra.42.fr/oauth/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'refresh_token',
          'refresh_token': refreshToken,
          'client_id': clientId,
          'client_secret': clientSecret,
        },
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;

        final newAccess = data['access_token'] as String?;
        final newRefresh = data['refresh_token'] as String?;
        final expiresIn = data['expires_in'] as int? ?? 7200;

        if (newAccess != null) {
          final newExpires = DateTime.now().millisecondsSinceEpoch + (expiresIn * 1000);
          debugPrint("refreshIfNeeded:     new token: ${newAccess}");

          await prefs.setString(_accessTokenKey, newAccess);
          if (newRefresh != null) {
            await prefs.setString(_refreshTokenKey, newRefresh);
          }
          await prefs.setInt(_expiresAtKey, newExpires);
          return true;
        }
      }
    } catch (e) {
      debugPrint("Auto refresh failed: $e");
    }

    await prefs.clear();
    return false;
  }

  Future<http.Response> get(String endpoint, int retries) async {
    if (!await _refreshIfNeeded()) {
      throw Exception('Token expired and refresh failed. Please login again.');
    }

    final token = await _getAccessToken();
    if (token == null) {
      throw Exception('No token available');
    }

    final res = await http.get(
      Uri.parse('https://api.intra.42.fr/v2$endpoint'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (res.statusCode == 429 && retries > 0) {
      debugPrint("ERROR 429: retry no: ${retries} to the endpoint: ${endpoint}");

      final retryAfter = int.tryParse(
        res.headers['retry-after'] ?? '',
      );

      final waitTime = Duration(
        seconds: retryAfter ?? 5,
      );

      await Future.delayed(waitTime);
      return get(endpoint, retries - 1);
    }
    return res;
  }
}
