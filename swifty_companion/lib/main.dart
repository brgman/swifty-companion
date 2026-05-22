import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '/components/oauth_login_form.dart';
import '/components/user.dart';
import '/components/search.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Swifty Companion',
      theme: ThemeData.dark(),
      home: const MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  Map<String, dynamic>? userData;
  Map<String, dynamic>? searchData;
  String? token;
  bool isLoggedIn = false;
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final username = _controller.text.trim();
    if (username.isEmpty) return;

    final res = await http.get(
      Uri.parse('https://api.intra.42.fr/v2/users?filter[login]=$username'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode >= 300) throw Exception('Failed to fetch /user');

    final data = jsonDecode(res.body);
    if (data is List && data.isNotEmpty) {
      _controller.clear();
      setState(() {
        searchData = data[0] as Map<String, dynamic>;
      });
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UserPage(userData: searchData!),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur: Utilisateur $username non trouvé"),
          backgroundColor: Colors.red,
        ),
      );
    }

    debugPrint(res.body);

    // return jsonDecode(res.body) as Map<String, dynamic>;

    
  }

  // Функция, которую будем вызывать из LoginPage
  void onLoginSuccess(Map<String, dynamic> data, String accessToken) {
    setState(() {
      userData = data;
      isLoggedIn = true;
      token = accessToken;
    });
  }

  void onLogout() {
    setState(() {
      userData = null;
      isLoggedIn = false;
      token = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final clientId = dotenv.get('CLIENT_ID');
    final clientSecret = dotenv.get('CLIENT_SECRET');
    final displayName = userData?['usual_full_name'] as String? ?? "";
    final imageUrl = userData?['image']?['link'] as String? ?? '';
    final location = userData?['location'] as String? ?? 'abergman';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('Current token: $token');
    });
     
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: Colors.grey[200],
              backgroundImage: imageUrl.isNotEmpty
                ? NetworkImage(imageUrl)
                : const AssetImage('logo.png'),
                ),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(imageUrl.isNotEmpty ? displayName : "swifty-companion"),
                Text(location,
                  style: const TextStyle(
                    fontSize: 14
                  )
                ),
              ]
            )
          ],
        ),
        actions:  imageUrl.isNotEmpty ? [
          TextButton.icon(
            onPressed: onLogout,
            icon: const Icon(Icons.logout, color: Colors.white),
            label: const Text(
              'Logout',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
          const SizedBox(width: 8),
        ] : [],
        backgroundColor: Colors.black,
        elevation: 2,
      ),
      body: isLoggedIn && (userData != null) && (token != null)
          ? SearchWidget(
            accessToken: token,
            controller: _controller,
            onSearch: _search,
          )
          : OAuthLoginForm(
            onLoginSuccess: onLoginSuccess,
            clientId: clientId,
            clientSecret: clientSecret,
          ),
    );
  }
}
