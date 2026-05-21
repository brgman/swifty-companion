import "package:flutter/material.dart";
import 'package:flutter_dotenv/flutter_dotenv.dart';
import "oauth_login_form.dart";

class LoginPage extends StatelessWidget {
    const LoginPage({super.key});

    @override
    Widget build(BuildContext context) {

        final clientId = dotenv.get('CLIENT_ID');
        final clientSecret = dotenv.get('CLIENT_SECRET');

        return Scaffold(
            appBar: AppBar(title: const Text("Login")),
            body: Padding(
                padding: const EdgeInsets.all(16),
                child: OAuthLoginForm(
                    clientId: clientId,
                    clientSecret: clientSecret,
                )
            )
        );
    }
}
