import 'failure.dart';

/// The outcome of an operation that can fail in an expected way.
///
/// Forces callers to handle the failure branch instead of letting an exception
/// escape into an unhandled async error.
sealed class Result<T> {
  const Result();

  const factory Result.ok(T value) = Ok<T>;
  const factory Result.err(Failure failure) = Err<T>;

  bool get isOk => this is Ok<T>;
  bool get isErr => this is Err<T>;

  /// The value, or null when this is a failure.
  T? get valueOrNull => switch (this) {
        Ok<T>(:final value) => value,
        Err<T>() => null,
      };

  /// The failure, or null when this succeeded.
  Failure? get failureOrNull => switch (this) {
        Ok<T>() => null,
        Err<T>(:final failure) => failure,
      };

  /// The value, or [fallback] when this is a failure.
  T valueOr(T fallback) => switch (this) {
        Ok<T>(:final value) => value,
        Err<T>() => fallback,
      };

  /// Collapses both branches into a single value.
  R fold<R>({
    required R Function(T value) onOk,
    required R Function(Failure failure) onErr,
  }) =>
      switch (this) {
        Ok<T>(:final value) => onOk(value),
        Err<T>(:final failure) => onErr(failure),
      };

  /// Transforms the success value, preserving a failure unchanged.
  Result<R> map<R>(R Function(T value) transform) => switch (this) {
        Ok<T>(:final value) => Ok(transform(value)),
        Err<T>(:final failure) => Err(failure),
      };
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);
  final T value;
}

final class Err<T> extends Result<T> {
  const Err(this.failure);
  final Failure failure;
}
