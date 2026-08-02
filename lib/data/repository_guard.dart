import 'package:sqflite/sqflite.dart';

import '../core/failure.dart';
import '../core/result.dart';

/// Translates storage exceptions into a [Failure] so no repository lets a raw
/// driver exception escape to the UI.
mixin RepositoryGuard {
  Future<Result<T>> guard<T>(String action, Future<T> Function() body) async {
    try {
      return Ok(await body());
    } on DatabaseException catch (e, s) {
      return Err(StorageFailure('Could not $action.', cause: _Traced(e, s)));
    } on FormatException catch (e, s) {
      return Err(ParseFailure('Could not $action: malformed data.',
          cause: _Traced(e, s)));
    } catch (e, s) {
      return Err(StorageFailure('Could not $action.', cause: _Traced(e, s)));
    }
  }
}

/// Keeps the stack trace attached to the cause for logging.
class _Traced {
  const _Traced(this.error, this.stackTrace);
  final Object error;
  final StackTrace stackTrace;

  @override
  String toString() => '$error\n$stackTrace';
}
