class Notification {
  final String id;
  final String senderId;
  final String receiverId;
  final String message;
  final String type; // 'meeting', 'approval', 'decline', 'general'
  final bool isRead;
  final DateTime createdAt;

  Notification({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  factory Notification.fromMap(Map<String, dynamic> map) {
    return Notification(
      id: (map['id'] ?? '').toString(),
      senderId: map['from_user_id'] ?? '',
      receiverId: map['to_user_id'] ?? '',
      message: map['message'] ?? '',
      type: map['type'] ?? 'general',
      isRead: map['is_read'] ?? false,
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'from_user_id': senderId,
      'to_user_id': receiverId,
      'message': message,
      'type': type,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Notification copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    String? message,
    String? type,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return Notification(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      message: message ?? this.message,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
} 