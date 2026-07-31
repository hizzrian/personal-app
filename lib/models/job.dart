import 'db_read.dart';

class Job {
  final String id;
  final String company;
  final String position;
  final String location;
  final String salary;
  final String status;
  final String notes;
  final DateTime appliedDate;
  final DateTime updatedAt;

  static const List<String> statuses = [
    'applied',
    'screening',
    'interview',
    'technical',
    'offer',
    'accepted',
    'rejected',
    'withdrawn',
  ];

  static const Map<String, String> statusLabels = {
    'applied': 'Applied',
    'screening': 'Screening',
    'interview': 'Interview',
    'technical': 'Technical',
    'offer': 'Offer',
    'accepted': 'Accepted',
    'rejected': 'Rejected',
    'withdrawn': 'Withdrawn',
  };

  static const Map<String, int> statusColors = {
    'applied': 0xFF00D4FF,
    'screening': 0xFFFBBF24,
    'interview': 0xFFA78BFA,
    'technical': 0xFFFF6B9D,
    'offer': 0xFF4ADE80,
    'accepted': 0xFF22C55E,
    'rejected': 0xFFF87171,
    'withdrawn': 0xFF888888,
  };

  Job({
    required this.id,
    required this.company,
    required this.position,
    this.location = '',
    this.salary = '',
    this.status = 'applied',
    this.notes = '',
    required this.appliedDate,
    required this.updatedAt,
  });

  /// Statuses that represent a closed application.
  static const Set<String> terminalStatuses = {'rejected', 'withdrawn', 'accepted'};

  /// Still in progress — not yet resolved either way.
  bool get isActive => !terminalStatuses.contains(status);

  /// Reached an offer, whether or not it was accepted.
  bool get isOffer => status == 'offer' || status == 'accepted';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'company': company,
      'position': position,
      'location': location,
      'salary': salary,
      'status': status,
      'notes': notes,
      'appliedDate': appliedDate.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Job.fromMap(Map<String, Object?> map) {
    final rawStatus = DbRead.string(map, 'status', fallback: 'applied');
    return Job(
      id: DbRead.string(map, 'id'),
      company: DbRead.string(map, 'company'),
      position: DbRead.string(map, 'position'),
      location: DbRead.string(map, 'location'),
      salary: DbRead.string(map, 'salary'),
      // Guard against an unknown status reaching the UI, where the colour and
      // label lookups would return null.
      status: statuses.contains(rawStatus) ? rawStatus : 'applied',
      notes: DbRead.string(map, 'notes'),
      appliedDate: DbRead.dateTime(map, 'appliedDate'),
      updatedAt: DbRead.dateTime(map, 'updatedAt'),
    );
  }

  Job copyWith({
    String? id,
    String? company,
    String? position,
    String? location,
    String? salary,
    String? status,
    String? notes,
    DateTime? appliedDate,
    DateTime? updatedAt,
  }) {
    return Job(
      id: id ?? this.id,
      company: company ?? this.company,
      position: position ?? this.position,
      location: location ?? this.location,
      salary: salary ?? this.salary,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      appliedDate: appliedDate ?? this.appliedDate,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
