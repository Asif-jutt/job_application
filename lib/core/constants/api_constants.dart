class ApiConstants {
  ApiConstants._();

  static const String baseUrl = 'https://jsonplaceholder.typicode.com';
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);

  /// Maps JSONPlaceholder posts to mock job listings.
  static const String externalJobsEndpoint = '/posts';
}
