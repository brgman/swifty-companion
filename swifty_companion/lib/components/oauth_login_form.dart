import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class OAuthLoginForm extends StatefulWidget {
  const OAuthLoginForm({
    super.key,
    required this.clientId,
    required this.clientSecret,
  });

  final String clientId;
  final String clientSecret;

  @override
  State<OAuthLoginForm> createState() => _OAuthLoginFormState();
}

class _OAuthLoginFormState extends State<OAuthLoginForm> {
  bool _loading = false;
  String? _status;

  Map<String, dynamic>? _meJson;
  String? _meJsonText;

  String? _accessToken;
  DateTime? _accessTokenExpiresAt;

  final int _callbackPort = 49443;
  String get _redirectUri => 'http://127.0.0.1:$_callbackPort/callback';

  bool get _hasValidAccessToken {
    if (_accessToken == null) return false;
    if (_accessTokenExpiresAt == null) return true;
    return DateTime.now().isBefore(_accessTokenExpiresAt!);
  }

  Future<String> _waitForOAuthCode() async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, _callbackPort);

    final completer = Completer<String>();

    server.listen((HttpRequest request) async {
      // Expected: /callback?code=...&state=...
      final code = request.uri.queryParameters['code'];
      final error = request.uri.queryParameters['error'];

      request.response
        ..statusCode = 200
        ..headers.contentType = ContentType.html
        ..write('<html><body>You can close this tab and go back to the app.</body></html>');
      await request.response.close();

      await server.close(force: true);

      if (error != null && !completer.isCompleted) {
        completer.completeError(Exception('OAuth error: $error'));
        return;
      }

      if (code == null || code.isEmpty) {
        completer.completeError(Exception('No "code" in callback URL: ${request.uri}'));
        return;
      }

      completer.complete(code);
    });

    return completer.future;
  }

  Future<void> _openBrowserForLogin() async {
    final uri = Uri.parse('https://api.intra.42.fr/oauth/authorize').replace(
      queryParameters: {
        'client_id': widget.clientId,
        'redirect_uri': _redirectUri,
        'response_type': 'code',
        'scope': 'public',
      },
    );

    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) throw Exception('Could not open browser');
  }

  Future<void> _exchangeCodeForTokenAndStore(String code) async {
    final res = await http.post(
      Uri.parse('https://api.intra.42.fr/oauth/token'),
      headers: const {
        'Accept': 'application/json',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'grant_type': 'authorization_code',
        'client_id': widget.clientId,
        'client_secret': widget.clientSecret,
        'code': code,
        'redirect_uri': _redirectUri,
      },
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Token exchange failed: ${res.statusCode}\n${res.body}');
    }

    final jsonMap = jsonDecode(res.body) as Map<String, dynamic>;
    final token = jsonMap['access_token'] as String?;
    final expiresIn = jsonMap['expires_in'] as int?; // seconds

    if (token == null || token.isEmpty) {
      throw Exception('No access_token in response: ${res.body}');
    }

    _accessToken = token;

    if (expiresIn != null && expiresIn > 10) {
      _accessTokenExpiresAt = DateTime.now().add(Duration(seconds: expiresIn - 10));
    } else if (expiresIn != null) {
      _accessTokenExpiresAt = DateTime.now().add(Duration(seconds: expiresIn));
    } else {
      _accessTokenExpiresAt = null;
    }

    debugPrint('token expires at $_accessTokenExpiresAt');
  }

  Future<String> _getAccessTokenInteractiveIfNeeded() async {
    if (_hasValidAccessToken) return _accessToken!;

    // interactive login (since 42 usually doesn't give refresh_token)
    final codeFuture = _waitForOAuthCode(); // start listening first
    await _openBrowserForLogin();
    final code = await codeFuture;

    await _exchangeCodeForTokenAndStore(code);
    return _accessToken!;
  }

  Future<Map<String, dynamic>> _fetchMe(String accessToken) async {
    // Real user endpoint:
    final res = await http.get(
      Uri.parse('https://api.intra.42.fr/v2/me'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
    );

    debugPrint('me_res=${res.body}');

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('GET /v2/me failed: ${res.statusCode}: ${res.body}');
    }

    final decoded = jsonDecode(res.body);
    if (decoded is Map) return Map<String, dynamic>.from(decoded);

    // (fallback if it ever returns list)
    if (decoded is List && decoded.isNotEmpty && decoded.first is Map) {
      return Map<String, dynamic>.from(decoded.first as Map);
    }

    throw Exception('Unexpected /v2/me response: ${decoded.runtimeType} ${res.body}');
  }

  Future<void> _connect() async {
    setState(() {
      _loading = true;
      _status = null;
      _meJson = null;
      _meJsonText = null;
    });

    try {
      setState(() => _status = 'Opening browser for 42 login...');
      final token = await _getAccessTokenInteractiveIfNeeded();

      setState(() => _status = 'Fetching /v2/me...');
      final me = await _fetchMe(token);

      setState(() {
        _status = 'Connected.';
        _meJson = me;
        _meJsonText = const JsonEncoder.withIndent('  ').convert(me);
      });
    } catch (e) {
      setState(() => _status = 'Login failed: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSuccess = (_status ?? '').startsWith('Connected');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton(
          onPressed: _loading ? null : _connect,
          child: Text(_loading ? 'Loading...' : 'Login with 42'),
        ),
        if (_status != null) ...[
          const SizedBox(height: 12),
          Text(
            _status!,
            style: TextStyle(color: isSuccess ? Colors.green : Colors.red),
          ),
        ],
        if (_meJson != null) ...[
          const SizedBox(height: 12),
          const Text('Response:'),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.black12,
            child: Text(
              _meJsonText ?? '',
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
        ],
      ],
    );
  }
}