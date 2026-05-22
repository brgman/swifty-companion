import 'dart:convert';
import "package:flutter/material.dart";
import 'package:flutter_dotenv/flutter_dotenv.dart';
import "oauth_login_form.dart";

class UserPage extends StatelessWidget {
  const UserPage({
    super.key,
    required this.userData,   // JSON данные от /v2/me
  });

  final Map<String, dynamic> userData;

  @override
  Widget build(BuildContext context) {
    final imageUrl = userData['image']?['link'] as String? ?? '';
    final login = userData['login'] as String? ?? 'Unknown';
    final displayName = userData['usual_full_name'] as String? ?? login;
    final email = userData['email'] as String? ?? '';
    final phone = userData['phone'] as String? ?? 'Not provided';
    final location = userData['location'] as String? ?? 'No location';
    final correctionPoint = userData['correction_point'] ?? 0;

    // debugPrint(const JsonEncoder.withIndent('  ').convert(userData));

    return Scaffold(
      appBar: AppBar(
        title: const Text("Search user"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Image.asset(
              '62d8d8adb0cfd56baad169a4c738af33.gif', // bugs-bunny-looney-tunes.gif
              width: 350,
              height: 350,
              fit: BoxFit.contain,
            ),
            Center(
              child: CircleAvatar(
                radius: 80,
                backgroundImage: imageUrl.isNotEmpty
                    ? NetworkImage(imageUrl)
                    : null,
                child: imageUrl.isEmpty
                    ? const Icon(Icons.person, size: 80)
                    : null,
              ),
            ),

            const SizedBox(height: 16),

            Text(
              displayName,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            Text(
              "@$login",
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),

            const SizedBox(height: 12),
            _buildInfoRow(Icons.email, "Email", email),
            _buildInfoRow(Icons.phone, "Phone", phone),
            _buildInfoRow(Icons.location_on, "Location", location),
            _buildInfoRow(Icons.star, "Correction Points", correctionPoint.toString()),
            _buildInfoRow(
              Icons.school,
              "Campus",
              userData['campus']?[0]?['name']?.toString() ?? 'Unknown',
            ),
            _buildInfoRow(
              Icons.money,
              "Wallet",
              "${userData['wallet'] ?? 0} EURO",
            ),
            _buildInfoRow(
              Icons.flag,
              "Level",
              "Level ${userData['level'] ?? 'N/A'}",
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget for nice rows
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(label),
        subtitle: Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}