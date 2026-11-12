/// Row of the `instructors` table (1:1 extension of `users`).
class Instructor {
  const Instructor({
    this.id,
    required this.userId,
    this.employeeNumber,
    this.specialization,
  });

  final int? id;
  final int userId;
  final String? employeeNumber;
  final String? specialization;

  factory Instructor.fromMap(Map<String, Object?> map) => Instructor(
    id: map['id'] as int?,
    userId: map['user_id'] as int,
    employeeNumber: map['employee_number'] as String?,
    specialization: map['specialization'] as String?,
  );

  /// id is omitted when null so SQLite fills it.
  Map<String, Object?> toMap() => {
    if (id != null) 'id': id,
    'user_id': userId,
    'employee_number': employeeNumber,
    'specialization': specialization,
  };

  Instructor copyWith({int? id}) => Instructor(
    id: id ?? this.id,
    userId: userId,
    employeeNumber: employeeNumber,
    specialization: specialization,
  );

  @override
  String toString() => 'Instructor(id: $id, userId: $userId)';
}

/// Read model for lists/forms: an instructor joined with his user account.
/// Never carries the password hash.
class InstructorInfo {
  const InstructorInfo({
    required this.instructor,
    required this.fullName,
    required this.username,
    this.email,
    required this.isActive,
  });

  final Instructor instructor;
  final String fullName;
  final String username;
  final String? email;
  final bool isActive;

  int get id => instructor.id!;
  int get userId => instructor.userId;
  String? get employeeNumber => instructor.employeeNumber;
  String? get specialization => instructor.specialization;

  /// Expects the columns of `InstructorDao`'s joined SELECT.
  factory InstructorInfo.fromMap(Map<String, Object?> map) => InstructorInfo(
    instructor: Instructor.fromMap(map),
    fullName: map['full_name'] as String,
    username: map['username'] as String,
    email: map['email'] as String?,
    isActive: (map['is_active'] as int) == 1,
  );
}
