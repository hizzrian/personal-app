/// A domain-level failure. Repositories translate low-level exceptions
/// (DatabaseException, FormatException, platform errors) into one of these so
/// the UI never has to interpret a driver-specific error.
sealed class Failure {
  const Failure(this.message, {this.cause});

  /// Human-readable, safe to show in a SnackBar.
  final String message;

  /// The original exception, kept for logging. Never shown to the user.
  final Object? cause;

  @override
  String toString() => '$runtimeType($message)';
}

/// Reading or writing local storage failed.
class StorageFailure extends Failure {
  const StorageFailure(super.message, {super.cause});
}

/// Input did not pass validation before it reached storage.
class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {super.cause});
}

/// External data (imported JSON, clipboard contents) was malformed.
class ParseFailure extends Failure {
  const ParseFailure(super.message, {super.cause});
}

/// A platform channel or OS-level operation failed (share sheet, clipboard).
class PlatformFailure extends Failure {
  const PlatformFailure(super.message, {super.cause});
}
