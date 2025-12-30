enum UserRole { admin, user }

class AuthSession {
  const AuthSession({
    required this.token,
    required this.role,
    required this.userId,
    required this.name,
    required this.email,
  });

  final String token;
  final UserRole role;
  final String userId;
  final String name;
  final String email;

  bool get isAdmin => role == UserRole.admin;
}
