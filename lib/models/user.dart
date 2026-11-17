import 'enums.dart';

/// Row of the `users` table.
class User {
  const User({
    this.id,
    required this.username,
    required this.passwordHash,
    required this.fullName,
    this.email,
    required this.role,
    this.isActive = true,
    this.createdAt,
  });

  final int? id;
  final String username;
  final String passwordHash;
  final String fullName;
  final String? email;
  final UserRole role;
  final bool isActive;
  final String? createdAt;

  factory User.fromMap(Map<String, Object?> map) => User(
        id: map['id'] as int?,
        username: map['username'] as String,
        passwordHash: map['password_hash'] as String,
        fullName: map['full_name'] as String,
        email: map['email'] as String?,
        role: UserRole.fromDb(map['user_type'] as String),
        isActive: (map['is_active'] as int) == 1,
        createdAt: map['created_at'] as String?,
      );

  /// id and created_at are omitted when null so SQLite fills them.
  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'username': username,
        'password_hash': passwordHash,
        'full_name': fullName,
        'email': email,
        'user_type': role.dbValue,
        'is_active': isActive ? 1 : 0,
        if (createdAt != null) 'created_at': createdAt,
      };

  User copyWith({int? id, String? passwordHash, bool? isActive}) => User(
        id: id ?? this.id,
        username: username,
        passwordHash: passwordHash ?? this.passwordHash,
        fullName: fullName,
        email: email,
        role: role,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt,
      );

  /// Never prints the hash.
  @override
  String toString() => 'User(id: $id, username: $username, role: ${role.name})';
}
