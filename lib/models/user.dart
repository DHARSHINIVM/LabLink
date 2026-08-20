class User {
  final int id;
  final String name;
  final String email;
  final String department;
  final String role;
  final bool isActive;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.department,
    required this.role,
    required this.isActive,
  });

  factory User.fromJson(
    Map<String, dynamic> json,
  ) {
    return User(
      id: json['id'] is int
          ? json['id'] as int
          : int.parse(
              json['id'].toString(),
            ),
      name:
          json['name']?.toString() ?? '',
      email:
          json['email']?.toString() ?? '',
      department:
          json['department']?.toString() ??
              '',
      role:
          json['role']?.toString() ??
              'student',
      isActive:
          json['is_active'] == true,
    );
  }

  bool get isAdmin =>
      role.toLowerCase() == 'admin';

  bool get isStudent =>
      role.toLowerCase() == 'student';
}