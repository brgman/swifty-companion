import "package:flutter/material.dart";
import "oauth_login_form.dart";

class LoginPage extends StatlessWidget {
    const LoginPage({super.key});

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(title: const Text("Login")),
            body: Padding(
                padding: const EdgeInsets.all(16),
                child: OAuthLoginForm(
                    clientId: "u-s4t2ud-e67ced9ce1d05a02dcea73179b0d7088c9fd95b681cfd5d5d05350bcd589ad3a",
                    clientSecret: "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",
                )
            )
        )
    }
}