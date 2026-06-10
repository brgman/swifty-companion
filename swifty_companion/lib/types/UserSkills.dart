class UserSkills {
  final String name;
  final Srting level;

  UserSkills({
    required this.name,
    required this.level,
  })

  factory UserSkills.fromJson(Map<String, dynamic> json) {
    return UserSkills(
      name: json['name'] ?? '',
      level: json['level'] ?? 0,
    );
  }
}

