class User {
  final String id;
  final String email;
  final String phone;
  final String role; // 'student', 'staff', 'admin'
  final String status; // 'pending', 'active', 'declined'
  final String? assignedStaffId;
  final String? username;
  final String? password;
  final DateTime createdAt;
  
  // Student-specific fields
  final String? enrollmentNo;
  final String? class_;
  final int? year;

  User({
    required this.id,
    required this.email,
    required this.phone,
    required this.role,
    required this.status,
    this.assignedStaffId,
    this.username,
    this.password,
    required this.createdAt,
    this.enrollmentNo,
    this.class_,
    this.year,
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      role: map['role'] ?? '',
      status: map['status'] ?? '',
      assignedStaffId: map['assigned_staff_id'],
      username: map['username'],
      password: map['password'],
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      enrollmentNo: map['enrollment_no'],
      class_: map['class'],
      year: map['year'] != null ? int.tryParse(map['year'].toString()) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'phone': phone,
      'role': role,
      'status': status,
      'assigned_staff_id': assignedStaffId,
      'username': username,
      'password': password,
      'created_at': createdAt.toIso8601String(),
      'enrollment_no': enrollmentNo,
      'class': class_,
      'year': year,
    };
  }

  User copyWith({
    String? id,
    String? email,
    String? phone,
    String? role,
    String? status,
    String? assignedStaffId,
    String? username,
    String? password,
    DateTime? createdAt,
    String? enrollmentNo,
    String? class_,
    int? year,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      status: status ?? this.status,
      assignedStaffId: assignedStaffId ?? this.assignedStaffId,
      username: username ?? this.username,
      password: password ?? this.password,
      createdAt: createdAt ?? this.createdAt,
      enrollmentNo: enrollmentNo ?? this.enrollmentNo,
      class_: class_ ?? this.class_,
      year: year ?? this.year,
    );
  }

  bool get isStudent => role == 'student';
  bool get isStaff => role == 'staff';
  bool get isAdmin => role == 'admin';
  bool get isPending => status == 'pending';
  bool get isActive => status == 'active';
  bool get isDeclined => status == 'declined';
} 