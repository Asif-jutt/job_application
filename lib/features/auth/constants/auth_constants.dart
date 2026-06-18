class AuthConstants {
  AuthConstants._();

  /// Web OAuth client ID from Firebase Console (required for Android Google Sign-In).
  static const String googleWebClientId =
      '533986648017-fhbrqua49f9jk50ik0m52panu4o4j27n.apps.googleusercontent.com';

  static const List<String> sensitiveUserFields = [
    'phone',
    'salary',
    'identityDocument',
  ];

  static const String emailHint = 'Enter your email';
  static const String passwordHint = 'Enter your password';
  static const String nameHint = 'Full name';
}
