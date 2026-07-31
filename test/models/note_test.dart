import 'package:flutter_test/flutter_test.dart';
import 'package:personal_app/models/note.dart';

void main() {
  Map<String, Object?> validRow() => {
        'id': 'n1',
        'title': 'Title',
        'body': 'Body',
        'tags': 'work,urgent',
        'color': 0,
        'isPinned': 1,
        'createdAt': '2026-01-01T00:00:00.000',
        'updatedAt': '2026-01-02T00:00:00.000',
      };

  group('Note.fromMap', () {
    test('reads a well-formed row', () {
      final note = Note.fromMap(validRow());
      expect(note.id, 'n1');
      expect(note.title, 'Title');
      expect(note.tags, ['work', 'urgent']);
      expect(note.isPinned, isTrue);
    });

    test('parses an empty tag string as no tags', () {
      final note = Note.fromMap(validRow()..['tags'] = '');
      expect(note.tags, isEmpty);
    });

    test('drops empty segments from a trailing comma', () {
      final note = Note.fromMap(validRow()..['tags'] = 'a,,b,');
      expect(note.tags, ['a', 'b']);
    });

    test('treats isPinned 0 as false', () {
      expect(Note.fromMap(validRow()..['isPinned'] = 0).isPinned, isFalse);
    });

    test('accepts a real bool for isPinned', () {
      // Imported JSON can carry true/false where SQLite stores 0/1.
      expect(Note.fromMap(validRow()..['isPinned'] = true).isPinned, isTrue);
    });

    test('does not throw on null text columns', () {
      final note = Note.fromMap(validRow()..['title'] = null);
      expect(note.title, '');
    });

    test('does not throw on a malformed date', () {
      expect(
        () => Note.fromMap(validRow()..['updatedAt'] = 'garbage'),
        returnsNormally,
      );
    });

    test('defaults a missing color to 0', () {
      final note = Note.fromMap(validRow()..['color'] = null);
      expect(note.color, 0);
    });
  });

  test('toMap round-trips through fromMap', () {
    final original = Note(
      id: 'n2',
      title: 'Round',
      body: 'Trip',
      tags: const ['x', 'y'],
      isPinned: true,
      createdAt: DateTime(2026, 2, 2),
      updatedAt: DateTime(2026, 2, 3),
    );
    final restored = Note.fromMap(original.toMap());

    expect(restored.id, original.id);
    expect(restored.title, original.title);
    expect(restored.tags, original.tags);
    expect(restored.isPinned, original.isPinned);
    expect(restored.updatedAt, original.updatedAt);
  });
}
