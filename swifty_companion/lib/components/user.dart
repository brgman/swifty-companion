import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class UserPage extends StatefulWidget {
  const UserPage({
    super.key,
    required this.token,
    required this.userData,
  });

  final String token;
  final Map<String, dynamic> userData;

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  late Map<String, dynamic> userData;
  late List<dynamic> skills;
  late String level;
  late String campus;
  late String token;
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    skills = [];
    level = "yy";
    campus = "";
    token = widget.token;
    userData = Map<String, dynamic>.from(widget.userData);

    final userId = widget.userData['id'];
    if (userId != null) {
      _fetchFullUserData(userId);
    } else {
      isLoading = false;
    }
  }

  Future<void> _fetchFullUserData(dynamic userId) async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final res = await http.get(
        Uri.parse('https://api.intra.42.fr/v2/users/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      // debugPrint("Status Code: ${res.statusCode}");

      if (res.statusCode == 200) {
        final fetchedData = json.decode(res.body) as Map<String, dynamic>;
        
        // debugPrint(const JsonEncoder.withIndent('  ').convert(fetchedData));

        List<dynamic> extractedSkills = [];
        String levelRes = "x";
        String campusName = "";
        try {
          final cursusUsers = fetchedData['cursus_users'] as List<dynamic>? ?? [];
          final filteredCursus = cursusUsers.where((cursus) {
          final cursusMap = cursus as Map<String, dynamic>;
            return cursusMap['cursus_id'] == 21;
          }).toList();

          if (filteredCursus.isNotEmpty) {
            final selectedCursus = filteredCursus.first as Map<String, dynamic>;
            extractedSkills = selectedCursus['skills'] as List<dynamic>? ?? [];
            levelRes = selectedCursus['level'].toString() ?? "1.0";
            
            final campusFromCursus = selectedCursus['campus'] as List<dynamic>? ?? [];
            if (campusFromCursus.isNotEmpty) {
              campusName = campusFromCursus[0]['name']?.toString() ?? "Unknown";
            } 
            else {
              final campusFromUser = fetchedData['campus'] as List<dynamic>? ?? [];
              if (campusFromUser.isNotEmpty) {
                campusName = campusFromUser[0]['name']?.toString() ?? "Unknown";
              }
            }

            debugPrint("campusName: ${campusName}");
          } else {
            if (cursusUsers.isNotEmpty) {
              final lastCursus = cursusUsers.last as Map<String, dynamic>;
              extractedSkills = lastCursus['skills'] as List<dynamic>? ?? [];
            }
          }
        } catch (e) {
          debugPrint("Error skills: $e");
        }

        setState(() {
          // userData = fetchedData;
          skills = extractedSkills;
          level = levelRes;
          campus = campusName;
          errorMessage = '';
        });
      } else {
        setState(() {
          errorMessage = "Error: ${res.statusCode}: ${res.body}";
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Error: $e";
      });
      debugPrint("Error: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = userData['image']?['link'] as String? ?? '';
    final login = userData['login'] as String? ?? 'Unknown';
    final displayName = userData['usual_full_name'] as String? ?? login;
    final email = userData['email'] as String? ?? '';
    final phone = userData['phone'] as String? ?? 'Not provided';
    final location = userData['location'] as String? ?? 'No location';
    final correctionPoint = userData['correction_point'] ?? 0;

    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text("Search user")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMessage.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("Search user")),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(errorMessage, textAlign: TextAlign.center),
          ),
        ),
      );
    }

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
            Center(
              child: CircleAvatar(
                radius: 80,
                backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                child: imageUrl.isEmpty ? const Icon(Icons.person, size: 80) : null,
              ),
            ),

            const SizedBox(height: 16),
            Text(displayName,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
            Text("@$login",
                style: const TextStyle(fontSize: 18, color: Colors.grey)),

            const SizedBox(height: 12),
            _buildInfoRow(Icons.email, "Email", email),
            _buildInfoRow(Icons.phone, "Phone", phone),
            _buildInfoRow(Icons.location_on, "Location", location),
            _buildInfoRow(Icons.star, "Correction Points", correctionPoint.toString()),
            _buildInfoRow(
              Icons.school,
              "Campus",
              campus ?? 'Unknown',
            ),
            _buildInfoRow(
              Icons.money,
              "Wallet",
              "${userData['wallet'] ?? 0} Y",
            ),
            _buildInfoRow(
              Icons.flag,
              "Level",
              "${level ?? 'N/A'}",
            ),

            const SizedBox(height: 24),
            
            Image.asset(
              '62d8d8adb0cfd56baad169a4c738af33.gif',
              width: 350,
              height: 350,
              fit: BoxFit.contain,
            ),

            const SizedBox(height: 24),
            const Text(
              "Skills",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            _buildSkillsContent()
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon, color: Colors.white),
        title: Text(label),
        subtitle: Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
      ),
    );
  }

  Widget _buildSkillsContent() {

    if (skills.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child: Text("No skills availablllllle"),
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: skills.map((skill) {
        final name = skill['name']?.toString() ?? 'Unknown';
        final level = (skill['level'] as num?)?.toDouble() ?? 0.0;
        return _buildSkillChip(name, level);
      }).toList(),
    );
  }

  Widget _buildSkillChip(String name, double level) {
    final percentage = (level / 20 * 100).clamp(0.0, 100.0);
    final int whole = level.floor();
    final String decimal = (level % 1).toStringAsFixed(2).substring(2);

    return Container(
      padding: const EdgeInsets.all(12),
      width: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            textAlign: TextAlign.start,
          ),
          const SizedBox(height: 12),
          Container(
            height: 8,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: (level / 20).clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'level ${whole} - ${decimal}%',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            Text(
              '(${percentage.toStringAsFixed(0)}%)',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        ],
      ),
    );
  }
}