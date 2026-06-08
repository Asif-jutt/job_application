import 'package:equatable/equatable.dart';

sealed class Result<T> extends Equatable {
  const Result();

  R when<R>({
    required R Function(T data) success,
    required R Function(String message, Object? error) failure,
  }) {
    return switch (this) {
      Success<T>(:final data) => success(data),
      Failure<T>(:final message, :final error) => failure(message, error),
    };
  }

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  T? get dataOrNull => switch (this) {
        Success<T>(:final data) => data,
        Failure<T>() => null,
      };
}

final class Success<T> extends Result<T> {
  const Success(this.data);
  final T data;

  @override
  List<Object?> get props => [data];
}

final class Failure<T> extends Result<T> {
  const Failure(this.message, [this.error]);
  final String message;
  final Object? error;

  @override
  List<Object?> get props => [message, error];
}
