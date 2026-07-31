import 'dart:convert';
import 'package:flutter_quill/flutter_quill.dart' show Document;

/// Note bodies are stored as a Quill Delta JSON array. Older notes predate the
/// rich-text editor and hold plain text, so every read has to tolerate both.
class NoteBody {
  const NoteBody._();

  /// Builds a Quill [Document] from a stored body, falling back to treating the
  /// body as plain text when it isn't valid Delta JSON.
  static Document toDocument(String body) {
    if (body.isEmpty) return Document();
    final delta = _tryDecodeDelta(body);
    if (delta != null) {
      try {
        return Document.fromJson(delta);
      } catch (_) {
        // Valid JSON but not a valid Delta — fall through to plain text.
      }
    }
    return Document()..insert(0, body);
  }

  /// Plain-text form, used for previews and search.
  static String toPlainText(String body) {
    if (body.isEmpty) return '';
    final delta = _tryDecodeDelta(body);
    if (delta == null) return body;
    try {
      return Document.fromJson(delta).toPlainText();
    } catch (_) {
      return body;
    }
  }

  /// Single-line preview with newlines collapsed.
  static String toPreview(String body) =>
      toPlainText(body).replaceAll('\n', ' ').trim();

  /// Returns the decoded Delta operation list, or null if [body] is not a
  /// JSON array (i.e. it's legacy plain text).
  static List<dynamic>? _tryDecodeDelta(String body) {
    try {
      final decoded = jsonDecode(body);
      return decoded is List ? decoded : null;
    } on FormatException {
      return null;
    }
  }
}
