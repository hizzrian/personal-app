import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:personal_app/utils/note_body.dart';

void main() {
  /// Quill requires a document's final insert to end with a newline, so the
  /// helper appends one when missing — otherwise Document.fromJson rejects it.
  String delta(String text) => jsonEncode([
        {'insert': text.endsWith('\n') ? text : '$text\n'},
      ]);

  group('NoteBody.toPlainText', () {
    test('extracts text from Delta JSON', () {
      expect(NoteBody.toPlainText(delta('Hello world\n')), 'Hello world\n');
    });

    test('returns empty for an empty body', () {
      expect(NoteBody.toPlainText(''), '');
    });

    test('falls back to the raw string for legacy plain-text notes', () {
      // Notes written before the rich-text editor are not JSON.
      expect(NoteBody.toPlainText('a legacy note'), 'a legacy note');
    });

    test('falls back for a JSON object that is not a Delta array', () {
      expect(NoteBody.toPlainText('{"not":"a delta"}'), '{"not":"a delta"}');
    });

    test('falls back for malformed JSON', () {
      expect(NoteBody.toPlainText('[{"insert":'), '[{"insert":');
    });

    test('falls back for a Delta array Quill rejects', () {
      // A Delta whose final insert lacks a trailing newline is invalid; the
      // helper must degrade gracefully rather than throw.
      const invalid = '[{"insert":"no trailing newline"}]';
      expect(NoteBody.toPlainText(invalid), invalid);
    });
  });

  group('NoteBody.toPreview', () {
    test('collapses newlines into spaces', () {
      expect(NoteBody.toPreview(delta('line one\nline two\n')), 'line one line two');
    });

    test('trims surrounding whitespace', () {
      expect(NoteBody.toPreview(delta('  padded  ')), 'padded');
    });

    test('handles legacy plain text', () {
      expect(NoteBody.toPreview('old\nnote'), 'old note');
    });
  });

  group('NoteBody.toDocument', () {
    test('round-trips Delta content', () {
      final doc = NoteBody.toDocument(delta('round trip\n'));
      expect(doc.toPlainText(), 'round trip\n');
    });

    test('wraps legacy plain text into a document', () {
      final doc = NoteBody.toDocument('plain');
      expect(doc.toPlainText().trim(), 'plain');
    });

    test('returns an empty document for an empty body', () {
      expect(NoteBody.toDocument('').toPlainText().trim(), '');
    });
  });
}
