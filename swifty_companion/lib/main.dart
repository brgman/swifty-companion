import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '/components/oauth_login_form.dart';
import '/components/user.dart';

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
  bool isLoggedIn = false;

  // Функция, которую будем вызывать из LoginPage
  void onLoginSuccess(Map<String, dynamic> data) {
    setState(() {
      userData = data;
      isLoggedIn = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final clientId = dotenv.get('CLIENT_ID');
    final clientSecret = dotenv.get('CLIENT_SECRET');
     
    return Scaffold(
      body: isLoggedIn && userData != null
          ? UserPage(userData: userData!)
          : OAuthLoginForm(
            onLoginSuccess: onLoginSuccess,
            clientId: clientId,
            clientSecret: clientSecret,
          ),
    );
  }
}