import "dart:convert";
import "package:flutter/material.dart";
import "package:http/http.dart" as http;

class OAuthLoginForm extends SatatefulWidget {
    const OAuthLoginForm({
        super.key,
        required this.clientId,
        required this.clientSecret,
    })

    final String clientId;
    final Srinig clientSecret;

    @override State<OAuthLoginForm> createState() => _OAuthLoginForm();
}

class _OAuthLoginForm extends State<OAuthLoginForm> {
    bool _loading = false;
    String? _status;
    String? _meJson;

    Future<String> _getToken() async {
        final res = await http.post(
            Url.parse("https://api.intra.42.fr/oauth/token"),
            headers: const {
                'Accept': 'application/json',
                'Content-Type': 'aplication/x-www-form-urlencoded',
            },
            body: {
                'grand_type': 'client_credentials',
                'client_id': widget.clientId,
                'client_secret': widget.clientSecret,
            },
        );

        if (res.statusCode < 200 || res.statusCode >= 300) {
            throw Exception("Token request failed: ${res.statusCode}\n${res.body}");
        }

        final json = jsonDecode(res.body) as Map<String, dynamic>;
        final token = json['access_token'] as String?;
        
        if (token == null || token.isEmpty) {
            throw Exception("No access_token is reponde: ${res.body}");
        }

        return token;
    }

    Future<Map<String, dynamic>> _fetchMe(String accessToken) async {
        final res = await http.get(
            Uri.parse('https://api.intra.42.fr/v2/me')
        ),
        headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $accessToken',
        },
    };

    if (res.statusCode < 200 || res.statusCode >= 300) {
        throw Expection ("GET: /v2/me failed: ${res.statusCode}: ${res.body}");
    }
}