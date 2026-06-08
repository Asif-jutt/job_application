sealed class NetworkException implements Exception {
  const NetworkException(this.message);
  final String message;

  @override
  String toString() => message;
}

final class ConnectionTimeoutException extends NetworkException {
  const ConnectionTimeoutException()
      : super('Connection timed out. Please check your network.');
}

final class ServerException extends NetworkException {
  const ServerException([super.message = 'Server error occurred.']);
}

final class NotFoundException extends NetworkException {
  const NotFoundException() : super('Requested resource was not found.');
}

final class UnauthorizedException extends NetworkException {
  const UnauthorizedException() : super('Unauthorized access.');
}

final class ParseException extends NetworkException {
  const ParseException([super.message = 'Failed to parse response data.']);
}

final class UnknownNetworkException extends NetworkException {
  const UnknownNetworkException([super.message = 'An unknown error occurred.']);
}

NetworkException mapDioException(Object error) {
  final message = error.toString();
  if (message.contains('connection timeout') ||
      message.contains('Connection timed out')) {
    return const ConnectionTimeoutException();
  }
  if (message.contains('404')) return const NotFoundException();
  if (message.contains('401') || message.contains('403')) {
    return const UnauthorizedException();
  }
  if (message.contains('500')) return const ServerException();
  return UnknownNetworkException(message);
}
