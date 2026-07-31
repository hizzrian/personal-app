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

  Note({
    required this.id,
    required this.title,
    required this.body,
    this.tags = const [],
    this.color = 0,
    this.isPinned = false,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'tags': tags.join(','),
      'color': color,
      'isPinned': isPinned ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Note.fromMap(Map<String, Object?> map) {
    return Note(
      id: DbRead.string(map, 'id'),
      title: DbRead.string(map, 'title'),
      body: DbRead.string(map, 'body'),
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
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      tags: tags ?? this.tags,
      color: color ?? this.color,
      isPinned: isPinned ?? this.isPinned,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
