class AuthConstants {
  AuthConstants._();

  static const List<String> sensitiveUserFields = [
    'phone',
    'salary',
    'identityDocument',
  ];

  static const String emailHint = 'Enter your email';
  static const String passwordHint = 'Enter your password';
  static const String nameHint = 'Full name';
}
