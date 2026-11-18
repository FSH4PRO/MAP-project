class Student {
  const Student({
    this.id,
    required this.studentNumber,
    required this.fullName,
    this.email,
    this.phone,
    this.department,
    this.enrollmentYear,
    this.isActive = true,
    this.createdAt,
  });

  final int? id;
  final String studentNumber;
  final String fullName;
  final String? email;
  final String? phone;
  final String? department;
  final int? enrollmentYear;
  final bool isActive;
  final String? createdAt;

  factory Student.fromMap(Map<String, Object?> map) => Student(
    id: map['id'] as int?,
    studentNumber: map['student_number'] as String,
    fullName: map['full_name'] as String,
    email: map['email'] as String?,
    phone: map['phone'] as String?,
    department: map['department'] as String?,
    enrollmentYear: map['enrollment_year'] as int?,
    isActive: (map['is_active'] as int? ?? 1) == 1,
    createdAt: map['created_at'] as String?,
  );

  Map<String, Object?> toMap() => {
    if (id != null) 'id': id,
    'student_number': studentNumber,
    'full_name': fullName,
    'email': email,
    'phone': phone,
    'department': department,
    'enrollment_year': enrollmentYear,
    'is_active': isActive ? 1 : 0,
    if (createdAt != null) 'created_at': createdAt,
  };

  Student copyWith({
    int? id,
    String? studentNumber,
    String? fullName,
    String? email,
    String? phone,
    String? department,
    int? enrollmentYear,
    bool? isActive,
    String? createdAt,
  }) => Student(
    id: id ?? this.id,
    studentNumber: studentNumber ?? this.studentNumber,
    fullName: fullName ?? this.fullName,
    email: email ?? this.email,
    phone: phone ?? this.phone,
    department: department ?? this.department,
    enrollmentYear: enrollmentYear ?? this.enrollmentYear,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt ?? this.createdAt,
  );
}

class StudentEnrollment {
  const StudentEnrollment({
    required this.subjectCode,
    required this.subjectName,
    required this.sectionNumber,
    required this.semester,
    required this.academicYear,
    required this.status,
  });

  final String subjectCode;
  final String subjectName;
  final String sectionNumber;
  final String semester;
  final String academicYear;
  final String status;

  factory StudentEnrollment.fromMap(Map<String, Object?> map) =>
      StudentEnrollment(
        subjectCode: map['subject_code'] as String,
        subjectName: map['subject_name'] as String,
        sectionNumber: map['section_number'] as String,
        semester: map['semester'] as String,
        academicYear: map['academic_year'] as String,
        status: map['status'] as String,
      );
}

class StudentAttendance {
  const StudentAttendance({
    required this.subjectName,
    required this.sectionNumber,
    required this.lectureDate,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.topic,
  });

  final String subjectName;
  final String sectionNumber;
  final String lectureDate;
  final String startTime;
  final String endTime;
  final String status;
  final String? topic;

  factory StudentAttendance.fromMap(Map<String, Object?> map) =>
      StudentAttendance(
        subjectName: map['subject_name'] as String,
        sectionNumber: map['section_number'] as String,
        lectureDate: map['lecture_date'] as String,
        startTime: map['start_time'] as String,
        endTime: map['end_time'] as String,
        status: map['attendance_status'] as String,
        topic: map['topic'] as String?,
      );
}
