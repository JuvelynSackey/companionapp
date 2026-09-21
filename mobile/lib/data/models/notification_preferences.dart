/// GET/PUT /api/users/me/notification-preferences
class NotificationPreferences {
  const NotificationPreferences({required this.pushEnabled, required this.registeredDevices});

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) => NotificationPreferences(
        pushEnabled: json['pushEnabled'] as bool,
        registeredDevices: json['registeredDevices'] as int,
      );

  /// Whether the server may send this user pushes at all.
  final bool pushEnabled;

  /// How many of this user's devices are registered for push.
  final int registeredDevices;

  NotificationPreferences copyWith({bool? pushEnabled}) => NotificationPreferences(
        pushEnabled: pushEnabled ?? this.pushEnabled,
        registeredDevices: registeredDevices,
      );
}
