import '../utils/note_body.dart';
import 'db_read.dart';

class Note {
  final String id;
  final String title;
  final String body;
  final List<String> tags;
  final int color;
  final bool isPinned;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Single-line plain text of [body], denormalised into its own column.
  ///
  /// Bodies are Quill Delta JSON, so deriving a preview on read meant decoding
  /// every note's Delta just to draw a list. It is computed once on write and
  /// read straight back; the constructor only derives it when a caller has no
  /// stored value to hand over.
  final String previewText;

  Note({
    required this.id,
    required this.title,
    required this.body,
    this.tags = const [],
    this.color = 0,
    this.isPinned = false,
    required this.createdAt,
    required this.updatedAt,
    String? previewText,
  }) : previewText = previewText ?? NoteBody.toPreview(body);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'previewText': previewText,
      'tags': tags.join(','),
      'color': color,
      'isPinned': isPinned ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Note.fromMap(Map<String, Object?> map) {
    // An empty column means the row predates v4 or was written by a path that
    // skipped the preview. Passing null lets the constructor derive one, so a
    // stale row costs the old parse instead of showing a blank line.
    final stored = DbRead.string(map, 'previewText');

    return Note(
      id: DbRead.string(map, 'id'),
      title: DbRead.string(map, 'title'),
      body: DbRead.string(map, 'body'),
      previewText: stored.isEmpty ? null : stored,
      tags: DbRead.csv(map, 'tags'),
      color: DbRead.integer(map, 'color'),
      isPinned: DbRead.boolean(map, 'isPinned'),
      createdAt: DbRead.dateTime(map, 'createdAt'),
      updatedAt: DbRead.dateTime(map, 'updatedAt'),
    );
  }

  Note copyWith({
    String? id,
    String? title,
    String? body,
    List<String>? tags,
    int? color,
    bool? isPinned,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? previewText,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      // A new body invalidates the old preview, so hand the constructor null
      // and let it re-derive rather than carrying over a stale line.
      previewText: previewText ?? (body == null ? this.previewText : null),
      tags: tags ?? this.tags,
      color: color ?? this.color,
      isPinned: isPinned ?? this.isPinned,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
