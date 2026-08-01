import 'db_read.dart';
import 'job_status.dart';

class Job {
  final String id;
  final String company;
  final String position;
  final String location;
  final String salary;
  final JobStatus status;
  final String notes;
  final DateTime appliedDate;
  final DateTime updatedAt;

  Job({
    required this.id,
    required this.company,
    required this.position,
    this.location = '',
    this.salary = '',
    this.status = JobStatus.applied,
    this.notes = '',
    required this.appliedDate,
    required this.updatedAt,
  });

  /// Still in progress — not yet resolved either way.
  bool get isActive => !status.isTerminal;

  /// Reached an offer, whether or not it was accepted.
  bool get isOffer => status.isOffer;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'company': company,
      'position': position,
      'location': location,
      'salary': salary,
      'status': status.dbValue,
      'notes': notes,
      'appliedDate': appliedDate.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Job.fromMap(Map<String, Object?> map) {
    return Job(
      id: DbRead.string(map, 'id'),
      company: DbRead.string(map, 'company'),
      position: DbRead.string(map, 'position'),
      location: DbRead.string(map, 'location'),
      salary: DbRead.string(map, 'salary'),
      status: JobStatus.fromDb(DbRead.string(map, 'status')),
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
    JobStatus? status,
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
