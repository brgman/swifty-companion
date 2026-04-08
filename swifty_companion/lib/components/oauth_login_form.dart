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
            Uri.parse('https://api.intra.42.fr/v2/me'),
            headers: {
                'Accept': 'application/json',
                'Authorization': 'Bearer $accessToken',
            },
        );

        if (res.statusCode < 200 || res.statusCode >= 300) {
           throw Expection ("GET: /v2/me failed: ${res.statusCode}: ${res.body}");
        }

        return jsonDecode(res.body) as Map<String, dynamic>;
    };

    Future<void> _connect() async {
        setState(() {
            _loading = true;
            _status = null;
            _meJson = null;
        });

        try {
            final token = await _getToken();
            final me = await _fetchMe(token);

            setState(( {
                _status = 'connected and fetched /v2/me.';
                _meJson = const jsonEncode(me);
            }))
        } catch (e) {
            setState(() {
                _status = 'connected and fetched /v2/me is failed. Error: ${e.toSting()}'
            })
        } finally {
            if (mounted) {
                setState(() => _loading = false);
            }
        }
    }

    @override
    Widget build(BuildContext context) {
        return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
                ElevatedButton(
                    onPressed: _loading ? null : _connect,
                    child: _loading 
                        ? const Text('Loading...')
                        : const Text('Fetch me')
                )

                if (_status != null) ...[
                    const SizedBox(height: 12),
                    Text(_status!, 
                        style: TextStyle(
                            color: _status!.startWith('Connected') 
                                ? Colors.green
                                : Colors.red
                        )
                    )
                ]

                if (_meJson != null) ...[
                    const SizedBox(height: 12),
                    const Text('Response: '),
                    const SizedBox(height: 6),
                    Container(
                        padding: const EdgeInsets.all(12),
                        color: Colors.black12,
                        child: Text(_meJson!, style: const TextStyle(fontFamily: 'monospace')),
                    ),
                ],
            ],
        );
    }
}