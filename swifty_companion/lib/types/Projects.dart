import 'package:intl/intl.dart';

class Project {
  final String name;
  final String slug;
  final int? finalMark;
  final String status;
  final bool? validated;
  final String? imageUrl;
  final DateTime createdAt;

  Project({
    required this.name,
    required this.slug,
    this.finalMark,
    required this.status,
    this.validated,
    this.imageUrl,
    required this.createdAt,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      name: json['project']['name'] as String,
      slug: json['project']['slug'] as String,
      finalMark: json['final_mark'] as int?,
      status: json['status'] as String,
      validated: json['validated?'] as bool?,
      imageUrl: json['project']['image_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  String get formattedCreatedAt => DateFormat.yMMMMd().add_jm().format(createdAt);
  // Or: DateFormat('dd/MM/yyyy HH:mm').format(createdAt);
}
