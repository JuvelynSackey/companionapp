import 'dart:async';

import 'package:mobile/core/services/notification_service.dart';
import 'package:mobile/core/services/push_messaging.dart';
import 'package:mobile/data/api/announcement_api.dart';
import 'package:mobile/data/api/device_api.dart';
import 'package:mobile/data/models/announcement.dart';
import 'package:mobile/data/models/notification_preferences.dart';

/// Shared fakes for the push-notification tests. Nothing here needs Firebase.

/// A push transport the test drives by hand.
class FakePushMessaging implements PushMessaging {
  FakePushMessaging({this.available = true, this.permissionGranted = true, this.token = 'fcm-token-1'});

  bool available;
  bool permissionGranted;
  String? token;
  PushMessage? initialMessage;
  Object? deleteTokenError;

  int permissionRequests = 0;
  int tokenDeletions = 0;

  final _refresh = StreamController<String>.broadcast();
  final _foreground = StreamController<PushMessage>.broadcast();
  final _opened = StreamController<PushMessage>.broadcast();

  void emitTokenRefresh(String value) => _refresh.add(value);
  void emitForeground(PushMessage message) => _foreground.add(message);
  void emitOpened(PushMessage message) => _opened.add(message);

  bool get hasListeners => _refresh.hasListener || _foreground.hasListener || _opened.hasListener;

  @override
  bool get isAvailable => available;

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return permissionGranted;
  }

  @override
  Future<String?> getToken() async => token;

  @override
  Stream<String> get onTokenRefresh => _refresh.stream;

  @override
  Stream<PushMessage> get onForegroundMessage => _foreground.stream;

  @override
  Stream<PushMessage> get onMessageOpened => _opened.stream;

  @override
  Future<PushMessage?> getInitialMessage() async => initialMessage;

  @override
  Future<void> deleteToken() async {
    tokenDeletions++;
    if (deleteTokenError != null) throw deleteTokenError!;
  }
}

/// An announcement push exactly as the backend sends it.
PushMessage announcementPush({int id = 7, String title = 'Exam timetable out', String body = 'See the portal.', String category = 'academic'}) =>
    PushMessage(
      title: title,
      body: body,
      data: {'type': 'announcement', 'announcementId': '$id', 'category': category},
    );

class FakeDeviceApi implements DeviceApi {
  final registered = <({String token, String platform})>[];
  final unregistered = <String>[];
  final events = <String>[];

  Object? registerError;
  Object? unregisterError;
  Object? preferencesError;
  Object? setPushError;
  Completer<void>? setPushGate;
  NotificationPreferences preferences = const NotificationPreferences(pushEnabled: true, registeredDevices: 1);

  @override
  Future<void> registerToken(String token, {required String platform}) async {
    events.add('register:$token');
    if (registerError != null) throw registerError!;
    registered.add((token: token, platform: platform));
  }

  @override
  Future<void> unregisterToken(String token) async {
    events.add('unregister:$token');
    if (unregisterError != null) throw unregisterError!;
    unregistered.add(token);
  }

  @override
  Future<NotificationPreferences> fetchPreferences() async {
    if (preferencesError != null) throw preferencesError!;
    return preferences;
  }

  @override
  Future<NotificationPreferences> setPushEnabled(bool enabled) async {
    await setPushGate?.future;
    if (setPushError != null) throw setPushError!;
    preferences = NotificationPreferences(pushEnabled: enabled, registeredDevices: preferences.registeredDevices);
    return preferences;
  }
}

/// Records what would have been shown, instead of touching the OS.
class FakeNotificationService implements NotificationService {
  final pushed = <({int id, String title, String body, bool isEmergency})>[];
  final announcements = <Announcement>[];
  Object? pushError;

  @override
  Future<void> showPushAnnouncement({
    required int announcementId,
    required String title,
    required String body,
    required bool isEmergency,
  }) async {
    if (pushError != null) throw pushError!;
    pushed.add((id: announcementId, title: title, body: body, isEmergency: isEmergency));
  }

  @override
  Future<void> showAnnouncementNotification(Announcement announcement) async => announcements.add(announcement);

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError('${invocation.memberName}');
}

Announcement announcement(int id, {String category = 'general'}) => Announcement(
      announcementId: id,
      title: 'Notice $id',
      message: 'Message $id',
      category: category,
      postedBy: 'Admin',
      datePosted: DateTime.utc(2030, 1, id),
    );

class FakeAnnouncementApiForPush implements AnnouncementApi {
  FakeAnnouncementApiForPush({this.cursor = 0, this.items = const []});

  int cursor;
  List<Announcement> items;
  int fetchCount = 0;
  final cursorUpdates = <int>[];

  @override
  Future<List<Announcement>> fetch({int limit = 50}) async {
    fetchCount++;
    return items;
  }

  @override
  Future<int> fetchSyncCursor() async => cursor;

  @override
  Future<int> updateSyncCursor(int lastSyncedAnnouncementId) async {
    cursorUpdates.add(lastSyncedAnnouncementId);
    cursor = lastSyncedAnnouncementId;
    return cursor;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError('${invocation.memberName}');
}
