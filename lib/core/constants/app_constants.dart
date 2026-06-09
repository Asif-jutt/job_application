class AppConstants {
  AppConstants._();

  static const String appName = 'Rozgar';
  static const String appTagline = 'Your Career, Your Way';

  static const String usersCollection = 'users';
  static const String jobsCollection = 'jobs';
  static const String chatsCollection = 'chats';
  static const String messagesSubcollection = 'messages';
  static const String applicationsCollection = 'applications';
  static const String statusSubcollection = 'status';
  static const String commentsSubcollection = 'comments';

  static const int chatPageSize = 25;
  static const int jobsPageSize = 20;
  static const int commentsPageSize = 20;

  static const Duration animationDuration = Duration(milliseconds: 350);
  static const Duration shimmerDuration = Duration(milliseconds: 1200);
}
