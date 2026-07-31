import 'package:flutter_test/flutter_test.dart';
import 'package:personal_app/core/result.dart';
import 'package:personal_app/data/app_database.dart';
import 'package:personal_app/data/note_repository.dart';
import 'package:personal_app/models/note.dart';

import '../support/test_database.dart';

void main() {
  setUpAll(initSqfliteForTests);

  late AppDatabase db;
  late NoteRepository repo;

  setUp(() {
    db = newTestDatabase();
    repo = SqliteNoteRepository(db);
  });

  tearDown(() => db.close());

  Note note({
    required String id,
    String title = 'Title',
    bool isPinned = false,
    DateTime? updatedAt,
  }) {
    final ts = updatedAt ?? DateTime(2026, 1, 1);
    return Note(
      id: id,
      title: title,
      body: 'body',
      tags: const ['tag'],
      isPinned: isPinned,
      createdAt: ts,
      updatedAt: ts,
    );
  }

  /// Unwraps an Ok, failing the test with the Failure message otherwise.
  T unwrap<T>(Result<T> result) => result.fold(
        onOk: (value) => value,
        onErr: (failure) => fail('expected Ok but got: ${failure.message}'),
      );

  test('starts empty', () async {
    expect(unwrap(await repo.all()), isEmpty);
    expect(unwrap(await repo.count()), 0);
  });

  test('saves and reads back a note', () async {
    unwrap(await repo.save(note(id: 'n1', title: 'Hello')));

    final all = unwrap(await repo.all());
    expect(all, hasLength(1));
    expect(all.single.id, 'n1');
    expect(all.single.title, 'Hello');
    expect(all.single.tags, ['tag']);
  });

  test('save is an upsert, not a duplicate insert', () async {
    unwrap(await repo.save(note(id: 'n1', title: 'First')));
    unwrap(await repo.save(note(id: 'n1', title: 'Second')));

    final all = unwrap(await repo.all());
    expect(all, hasLength(1));
    expect(all.single.title, 'Second');
  });

  test('orders pinned notes first, then by recency', () async {
    unwrap(await repo.save(note(id: 'old', updatedAt: DateTime(2026, 1, 1))));
    unwrap(await repo.save(note(id: 'new', updatedAt: DateTime(2026, 6, 1))));
    unwrap(await repo.save(
      note(id: 'pinned', isPinned: true, updatedAt: DateTime(2025, 1, 1)),
    ));

    final ids = unwrap(await repo.all()).map((n) => n.id).toList();
    // Pinned wins over recency; among the rest, newest first.
    expect(ids, ['pinned', 'new', 'old']);
  });

  test('setPinned toggles the flag and bumps updatedAt', () async {
    unwrap(await repo.save(note(id: 'n1')));
    final before = unwrap(await repo.all()).single;

    unwrap(await repo.setPinned('n1', pinned: true));
    final after = unwrap(await repo.all()).single;

    expect(after.isPinned, isTrue);
    expect(after.updatedAt.isAfter(before.updatedAt), isTrue);
  });

  test('setPinned preserves the rest of the row', () async {
    unwrap(await repo.save(note(id: 'n1', title: 'Keep me')));
    unwrap(await repo.setPinned('n1', pinned: true));

    final updated = unwrap(await repo.all()).single;
    expect(updated.title, 'Keep me');
    expect(updated.tags, ['tag']);
  });

  test('delete removes only the target row', () async {
    unwrap(await repo.save(note(id: 'n1')));
    unwrap(await repo.save(note(id: 'n2')));

    unwrap(await repo.delete('n1'));

    final ids = unwrap(await repo.all()).map((n) => n.id).toList();
    expect(ids, ['n2']);
  });

  test('deleting a missing id is not an error', () async {
    expect((await repo.delete('nope')).isOk, isTrue);
  });

  test('recent respects the limit and returns newest first', () async {
    for (var i = 0; i < 5; i++) {
      unwrap(await repo.save(
        note(id: 'n$i', updatedAt: DateTime(2026, 1, i + 1)),
      ));
    }

    final recent = unwrap(await repo.recent(limit: 3));
    expect(recent.map((n) => n.id).toList(), ['n4', 'n3', 'n2']);
  });

  test('count reflects inserts and deletes', () async {
    unwrap(await repo.save(note(id: 'n1')));
    unwrap(await repo.save(note(id: 'n2')));
    expect(unwrap(await repo.count()), 2);

    unwrap(await repo.delete('n1'));
    expect(unwrap(await repo.count()), 1);
  });

  test('returns Err instead of throwing when the table is missing', () async {
    // Drop the table out from under the repository to simulate a real
    // DatabaseException. The API must surface it as Err, never throw.
    final raw = await db.open();
    await raw.execute('DROP TABLE ${AppDatabase.tableNotes}');

    final result = await repo.all();

    expect(result.isErr, isTrue);
    expect(result.failureOrNull?.message, contains('Could not load notes'));
  });

  test('a failing write also returns Err', () async {
    final raw = await db.open();
    await raw.execute('DROP TABLE ${AppDatabase.tableNotes}');

    final result = await repo.save(note(id: 'n1'));

    expect(result.isErr, isTrue);
    expect(result.failureOrNull?.message, contains('Could not save note'));
  });
}
