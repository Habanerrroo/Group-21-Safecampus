enum UserRole { student, security, admin }

class User {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? studentId;
  final String? profileImage;
  final bool isActive;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.studentId,
    this.profileImage,
    this.isActive = true,
  });
}
