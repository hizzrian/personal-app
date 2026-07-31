import 'db_read.dart';

class QrItem {
  final String id;
  final String label;
  final String data;
  final DateTime createdAt;

  QrItem({
    required this.id,
    required this.label,
    required this.data,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'label': label,
      'data': data,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory QrItem.fromMap(Map<String, Object?> map) {
    return QrItem(
      id: DbRead.string(map, 'id'),
      label: DbRead.string(map, 'label'),
      data: DbRead.string(map, 'data'),
      createdAt: DbRead.dateTime(map, 'createdAt'),
    );
  }
}
