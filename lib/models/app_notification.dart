enum AppNotificationType { busApproaching, occupancyUpdate, routeStatus }

class AppNotification {
  final String id;
  final AppNotificationType type;
  final String title;
  final String body;
  final DateTime time;
  bool isRead;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.time,
    this.isRead = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'title': title,
    'body': body,
    'time': time.toIso8601String(),
    'isRead': isRead,
  };

  static AppNotification fromJson(Map<String, dynamic> json) => AppNotification(
    id: json['id'] as String,
    type: AppNotificationType.values.firstWhere(
      (t) => t.name == json['type'],
      orElse: () => AppNotificationType.routeStatus,
    ),
    title: json['title'] as String,
    body: json['body'] as String,
    time: DateTime.parse(json['time'] as String),
    isRead: json['isRead'] as bool? ?? false,
  );
}
