class RouteConstants {
  RouteConstants._();

  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';

  // User (Job Seeker)
  static const String userHome = '/user';
  static const String userJobs = '/user/jobs';
  static const String userJobDetail = '/user/jobs/:jobId';
  static const String userProfile = '/user/profile';
  static const String userChats = '/user/chats';
  static const String userChat = '/user/chats/:chatId';

  // Company (Recruiter)
  static const String companyHome = '/company';
  static const String companyPostJob = '/company/post-job';
  static const String companyApplications = '/company/applications';
  static const String companyProfile = '/company/profile';
  static const String companyChats = '/company/chats';
  static const String companyChat = '/company/chats/:chatId';

  // Admin
  static const String adminHome = '/admin';
  static const String adminUsers = '/admin/users';
  static const String adminJobs = '/admin/jobs';
  static const String adminAnalytics = '/admin/analytics';
  static const String adminProfile = '/admin/profile';
}
