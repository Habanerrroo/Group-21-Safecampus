class User {
  final String id;
  final String name;
  final String email;
  final String? studentId;
  final String? phone;
  final String? residence;
  final UserRole role;
  final String? profileImage;
  final DateTime createdAt;
  final bool isActive;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.studentId,
    this.phone,
    this.residence,
    required this.role,
    this.profileImage,
    required this.createdAt,
    this.isActive = true,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      studentId: json['studentId'],
      phone: json['phone'],
      residence: json['residence'],
      role: UserRoleExtension.fromString(json['role'] ?? 'student'),
      profileImage: json['profileImage'],
      createdAt: DateTime.parse(json['createdAt']),
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'studentId': studentId,
      'phone': phone,
      'residence': residence,
      'role': role.name,
      'profileImage': profileImage,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
    };
  }
}

enum UserRole {
  student,
  security,
  admin,
}

extension UserRoleExtension on UserRole {
  String get name {
    switch (this) {
      case UserRole.student:
        return 'student';
      case UserRole.security:
        return 'security';
      case UserRole.admin:
        return 'admin';
    }
  }

  static UserRole fromString(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'security':
        return UserRole.security;
      case 'student':
      default:
        return UserRole.student;
    }
  }
}
