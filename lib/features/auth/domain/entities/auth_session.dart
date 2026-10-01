class AuthSession {
  final String userId;
  final String token;
  final DateTime expiresAt;

  const AuthSession({
    required this.userId,
    required this.token,
    required this.expiresAt,
  });

  bool get isValid => userId.isNotEmpty && token.isNotEmpty &&
      expiresAt.isAfter(DateTime.now());
}
