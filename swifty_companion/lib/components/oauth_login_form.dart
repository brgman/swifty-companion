import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

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

  Future<String> _getToken() async {
    final res = await http.post(
      Uri.parse('https://api.intra.42.fr/oauth/token'),
      headers: const {
        'Accept': 'application/json',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'grant_type': 'client_credentials',
        'client_id': widget.clientId,
        'client_secret': widget.clientSecret,
      },
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Token request failed: ${res.statusCode}\n${res.body}');
    }

    final jsonMap = jsonDecode(res.body) as Map<String, dynamic>;
    final token = jsonMap['access_token'] as String?;

    if (token == null || token.isEmpty) {
      throw Exception('No access_token in response: ${res.body}');
    }

    return token;
  }

  Future<Map<String, dynamic>> _fetchMe(String accessToken) async {
    final res = await http.get(
      Uri.parse('https://api.intra.42.fr/v2/users')
        .replace(queryParameters: {'filter[login]': 'abergman'}),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
    );

    //  debugPrint('me_res=${res.body}');

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('GET /v2/me failed: ${res.statusCode}: ${res.body}');
    }

    final decoded = jsonDecode(res.body);

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
    });

    try {
      final token = await _getToken();
      final me = await _fetchMe(token);

    debugPrint('me=$me');

      setState(() {
        _status = 'Connected and fetched /v2/me.';
        _meJson = me;
        _meJsonText = const JsonEncoder.withIndent('  ').convert(me);
    });
    } catch (e) {
      setState(() {
        _status = 'Fetch /v2/me failed. Error: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
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
          child: Text(_loading ? 'Loading...' : 'Fetch me'),
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
              _meJsonText!,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
        ],
      ],
    );
  }
}