import 'package:flutter/material.dart';
import '/components/login_page.dart';
import "package:flutter_dotenv/flutter_dotenv.dart";

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();   // ← Add this

  await dotenv.load(fileName: ".env");   // ← Correct

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: LoginPage(),   // or your starting page
      debugShowCheckedModeBanner: true,
    );
  }
}