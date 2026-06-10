import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'user.dart';
import 'package:flutter/foundation.dart'; // for kIsWeb
import 'dart:html' as html_tree;
import 'package:shared_preferences/shared_preferences.dart';

class OAuthLoginForm extends StatefulWidget {
  const OAuthLoginForm({
    super.key,
    required this.clientId,
    required this.clientSecret,
    required this.onLoginSuccess,
  });

  final String clientId;
  final String clientSecret;
  final Function(Map<String, dynamic>, String)? onLoginSuccess;

  @override
  State<OAuthLoginForm> createState() => _OAuthLoginFormState();
}

class _OAuthLoginFormState extends State<OAuthLoginForm> {
  bool _loading = false;
  String? _status;
  Map<String, dynamic>? _meJson;
  String? _meJsonText;
  String? _accessToken;

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _expiresAtKey = 'expires_at';

  // For Web: redirect to the current page
  String get _redirectUri {
    if (kIsWeb) {
      final uri = Uri.base;
      return '${uri.origin}/callback';
    }
    return 'http://localhost:4444/callback';
  }

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _checkForCallbackInUrl();   // Check if we came back with ?code=...
    }
    tryAutoLogin();
  }

  Future<void> tryAutoLogin() async {
    debugPrint("tryAutoLogin");
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_accessTokenKey);
    final expiresAt = prefs.getInt(_expiresAtKey) ?? 0;

    if (token != null && DateTime.now().millisecondsSinceEpoch < expiresAt) {
      final me = await _fetchMe(token);
      if (me != null) {
        setState(() {
          _accessToken = token;
          _meJson = me;
          _status = 'Recovery prev session';
        });
        widget.onLoginSuccess?.call(me, token);
      }
    }
  }

  void _checkForCallbackInUrl() {
    final uri = Uri.base;
    final code = uri.queryParameters['code'];
    final error = uri.queryParameters['error'];

    if (error != null) {
      setState(() => _status = 'OAuth Error: $error');
      return;
    }

    if (code != null && code.isNotEmpty) {
      setState(() => _status = 'Received code, exchanging for token...');
      _exchangeCodeForTokenAndStore(code);
    }
  }

  void _cleanUrl() {
    if (!kIsWeb) return;

    try {
      final cleanUri = Uri.base.replace(queryParameters: {});
      html_tree.window.history.replaceState(
        null, 
        '', 
        cleanUri.toString(),
      );
    } catch (e) {
      debugPrint('Failed to clean URL: $e');
    }
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

    if (kIsWeb) {
      html_tree.window.location.href = uri.toString();
    } else {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    }
  }

  Future<void> _exchangeCodeForTokenAndStore(String code) async {
    try {
      final res = await http.post(
        Uri.parse('https://api.intra.42.fr/oauth/token'),
        headers: {
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

      if (res.statusCode >= 300) {
        throw Exception('Token exchange failed: ${res.statusCode}\n${res.body}');
      }

      final jsonMap = jsonDecode(res.body) as Map<String, dynamic>;
      final token = jsonMap['access_token'] as String?;
      final refreshToken = jsonMap['refresh_token'] as String?;
      final expiresIn = jsonMap['expires_in'] as int?;

      if (token == null || token.isEmpty) {
        throw Exception('No access_token received');
      }

      await saveTokens(token, refreshToken, expiresIn ?? 7200);

      _cleanUrl();

      // Fetch user data
      final me = await _fetchMe(token);
      setState(() {
        _accessToken = token;
        _status = 'Connected successfully!';
        _meJson = me;
        _meJsonText = const JsonEncoder.withIndent('  ').convert(me);
      });
    } catch (e) {
      setState(() => _status = 'Error: $e');
    }
  }

  Future<void> saveTokens(String accessToken, String? refreshToken, int expiresIn) async {
    debugPrint("saveTokens");
    final prefs = await SharedPreferences.getInstance();
    final expiresAt = DateTime.now().millisecondsSinceEpoch + (expiresIn * 1000);

    await prefs.setString(_accessTokenKey, accessToken);
    if (refreshToken != null) {
      await prefs.setString(_refreshTokenKey, refreshToken);
    }
    await prefs.setInt(_expiresAtKey, expiresAt);
  }

  Future<bool> refreshAccessToken() async {
    debugPrint("refreshAccessToken");
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString(_refreshTokenKey);

    if (refreshToken == null) return false;

    try {
      final res = await http.post(
        Uri.parse('https://api.intra.42.fr/oauth/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'refresh_token',
          'refresh_token': refreshToken,
          'client_id': widget.clientId,
          'client_secret': widget.clientSecret,
        },
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        await saveTokens(
          data['access_token'],
          data['refresh_token'] ?? refreshToken,
          data['expires_in'] ?? 7200,
        );
        return true;
      }
    } catch (e) {
      debugPrint("Refresh token error: $e");
    }

    await prefs.clear();
    return false;
  }

  Future<Map<String, dynamic>> _fetchMe(String accessToken) async {
    final res = await http.get(
      Uri.parse('https://api.intra.42.fr/v2/me'),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (res.statusCode >= 300) throw Exception('Failed to fetch /me');

    debugPrint(res.body);

    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<void> _connect() async {
    setState(() {
      _loading = true;
      _status = null;
      _meJson = null;
    });

    try {
      setState(() => _status = '');
      await _openBrowserForLogin();
      // On Web, the rest happens in _checkForCallbackInUrl()
    } catch (e) {
      setState(() => _status = 'Failed: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSuccess = _status?.contains('Connected') == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 50),
        Image.asset(
          'bugs-bunny-looney-tunes.gif',
          width: 220,
          height: 220,
          fit: BoxFit.contain,
        ),
        Padding(
          padding: const EdgeInsets.all(42.0),
          child: ElevatedButton(
          onPressed: _loading ? null : _connect,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'logo.png',
                  height: 40,
                  width: 40,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.business, size: 40, color: Colors.black);
                  },
                ),
              const SizedBox(width: 12),
              const Text(
                'Login with 42',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        ),
        

        if (_status != null) ...[
          const SizedBox(height: 16),
          Text(
            _status!,
            style: TextStyle(
              color: isSuccess ? Colors.green : Colors.white,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],

        if (_meJson != null && widget.onLoginSuccess != null)
          Builder(
            builder: (context) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                widget.onLoginSuccess!(_meJson!, _accessToken!);
              });
              return const SizedBox.shrink();
            },
          ),
      ],
    );
  }
}