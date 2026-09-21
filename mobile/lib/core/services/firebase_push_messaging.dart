import 'package:firebase_messaging/firebase_messaging.dart';
import 'push_messaging.dart';

/// PushMessaging over Firebase Cloud Messaging. Only ever constructed by
/// push_bootstrap.dart, after Firebase.initializeApp() succeeded. This is the
/// single file that touches firebase_messaging; it is not unit-tested (it needs
/// a real Firebase project), so it is kept as thin as possible: each member is
/// one call plus the conversion to the app's own types.
class FirebasePushMessaging implements PushMessaging {
  FirebasePushMessaging([FirebaseMessaging? messaging]) : _messaging = messaging ?? FirebaseMessaging.instance;

  final FirebaseMessaging _messaging;

  @override
  bool get isAvailable => true;

  @override
  Future<bool> requestPermission() async {
    final settings = await _messaging.requestPermission();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  @override
  Future<String?> getToken() => _messaging.getToken();

  @override
  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;

  @override
  Stream<PushMessage> get onForegroundMessage => FirebaseMessaging.onMessage.map(_convert);

  @override
  Stream<PushMessage> get onMessageOpened => FirebaseMessaging.onMessageOpenedApp.map(_convert);

  @override
  Future<PushMessage?> getInitialMessage() async {
    final message = await _messaging.getInitialMessage();
    return message == null ? null : _convert(message);
  }

  @override
  Future<void> deleteToken() => _messaging.deleteToken();

  static PushMessage _convert(RemoteMessage message) => PushMessage(
        title: message.notification?.title,
        body: message.notification?.body,
        data: {for (final entry in message.data.entries) entry.key: '${entry.value}'},
      );
}
