import 'package:personal_app/data/app_database.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Call once per test file before opening any database.
void initSqfliteForTests() {
  sqfliteFfiInit();
}

/// A fresh in-memory database, isolated per test.
AppDatabase newTestDatabase() => AppDatabase(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );
