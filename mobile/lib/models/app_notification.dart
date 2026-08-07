class AppNotification {
  final int id;
  final int userId;
  final String? title;
  final String? message;
  final bool isRead;
  final String? createdAt;

  const AppNotification({
    required this.id,
    required this.userId,
    this.title,
    this.message,
    required this.isRead,
    this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      title: json['title'] as String?,
      message: json['message'] as String?,
      isRead: (json['is_read'] == true || json['is_read'] == 1),
      createdAt: json['created_at'] as String?,
    );
  }
}
