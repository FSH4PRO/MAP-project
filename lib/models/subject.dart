class Subject {
  const Subject({
    this.id,
    required this.subjectCode,
    required this.subjectName,
    required this.creditHours,
    this.department,
    this.isActive = true,
  });

  final int? id;
  final String subjectCode;
  final String subjectName;
  final int creditHours;
  final String? department;
  final bool isActive;

  factory Subject.fromMap(Map<String, Object?> map) => Subject(
        id: map['id'] as int?,
        subjectCode: map['subject_code'] as String,
        subjectName: map['subject_name'] as String,
        creditHours: map['credit_hours'] as int,
        department: map['department'] as String?,
        isActive: (map['is_active'] as int? ?? 1) == 1,
      );

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'subject_code': subjectCode,
        'subject_name': subjectName,
        'credit_hours': creditHours,
        'department': department,
        'is_active': isActive ? 1 : 0,
      };

  Subject copyWith({
    int? id,
    String? subjectCode,
    String? subjectName,
    int? creditHours,
    String? department,
    bool? isActive,
  }) =>
      Subject(
        id: id ?? this.id,
        subjectCode: subjectCode ?? this.subjectCode,
        subjectName: subjectName ?? this.subjectName,
        creditHours: creditHours ?? this.creditHours,
        department: department ?? this.department,
        isActive: isActive ?? this.isActive,
      );
}
