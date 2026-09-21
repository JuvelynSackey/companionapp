/// What the app needs from a push service, without naming Firebase. The real
/// implementation is FirebasePushMessaging; when push is not configured the app
/// uses [NoopPushMessaging], and tests use a fake. Nothing else in the app
/// imports firebase_messaging, so it stays optional.
abstract class PushMessaging {
  /// False when push is not set up (no Firebase project / feature off). Every
  /// other member is then inert and the UI hides its push controls.
  bool get isAvailable;

  /// Asks the OS for permission to show notifications. True if granted.
  Future<bool> requestPermission();

  /// This install's push token, or null if it cannot be obtained.
  Future<String?> getToken();

  /// Fires when the service issues a new token for this install.
  Stream<String> get onTokenRefresh;

  /// A message that arrived while the app is open. (While it is closed or in
  /// the background the OS shows the notification itself.)
  Stream<PushMessage> get onForegroundMessage;

  /// The user tapped a notification while the app was in the background.
  Stream<PushMessage> get onMessageOpened;

  /// The notification whose tap launched the app from closed, if any.
  Future<PushMessage?> getInitialMessage();

  /// Forgets this install's token so a new one is issued. Used on sign-out so
  /// the next account on a shared phone does not inherit it.
  Future<void> deleteToken();
}

/// A push message as the app sees it, whatever the transport.
class PushMessage {
  const PushMessage({this.title, this.body, this.data = const {}});

  final String? title;
  final String? body;

  /// The custom payload the server attached, e.g. {type: announcement,
  /// announcementId: 7, category: emergency}. Values are strings.
  final Map<String, String> data;

  bool get isAnnouncement => data['type'] == 'announcement';
  int? get announcementId => int.tryParse(data['announcementId'] ?? '');
  bool get isEmergency => data['category'] == 'emergency';
}

/// The default: push is not configured. Nothing is requested, sent or shown.
class NoopPushMessaging implements PushMessaging {
  const NoopPushMessaging();

  @override
  bool get isAvailable => false;

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<String?> getToken() async => null;

  @override
  Stream<String> get onTokenRefresh => const Stream.empty();

  @override
  Stream<PushMessage> get onForegroundMessage => const Stream.empty();

  @override
  Stream<PushMessage> get onMessageOpened => const Stream.empty();

  @override
  Future<PushMessage?> getInitialMessage() async => null;

  @override
  Future<void> deleteToken() async {}
}
