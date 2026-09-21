import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/alerts/alerts_providers.dart';
import '../../features/shell/nav_providers.dart';
import '../providers/core_providers.dart';
import 'push_messaging.dart';

/// The push transport. NoopPushMessaging until main() swaps in the real one.
final pushMessagingProvider = Provider<PushMessaging>((ref) => const NoopPushMessaging());

/// True while this device is registered with the server for push. The
/// announcement poll reads it: while push works the poll stays quiet (the
/// server pushes instead), and if push is not working the poll keeps notifying
/// as before, so nobody loses alerts because push failed to register.
final pushActiveProvider = StateProvider<bool>((ref) => false);

/// What to tell the server this device is. Overridable for tests.
final pushPlatformProvider = Provider<String>((ref) {
  if (kIsWeb) return 'web';
  return defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';
});

final pushCoordinatorProvider = Provider<PushCoordinator>((ref) {
  final coordinator = PushCoordinator(ref);
  // Only cancel the listeners: when the container is being torn down, other
  // providers can no longer be read, so stop()'s state update would throw.
  ref.onDispose(coordinator._cancelListeners);
  return coordinator;
});

/// Owns this device's push lifecycle:
///
///  * [start] (signed in): ask permission, get the token, register it with the
///    server, keep it registered as it rotates, and react to messages.
///  * a message while the app is open -> show it as a notification and refresh
///    the Alerts list; a tap on a notification -> open the Alerts tab.
///  * [unregisterCurrentDevice] (signing out): tell the server to stop, and
///    forget the token so the next account on this phone gets a fresh one.
///
/// Every failure is swallowed and leaves push simply inactive: push is an
/// enhancement, and the announcement poll still covers the app being open.
class PushCoordinator {
  PushCoordinator(this._ref);

  final Ref _ref;
  final List<StreamSubscription<Object?>> _subscriptions = [];
  String? _registeredToken;
  bool _starting = false;

  PushMessaging get _messaging => _ref.read(pushMessagingProvider);

  /// Safe to call again while already started (does nothing).
  Future<void> start() async {
    if (!_messaging.isAvailable || _starting || _subscriptions.isNotEmpty) return;
    _starting = true;
    try {
      if (!await _messaging.requestPermission()) return;

      _subscriptions
        ..add(_messaging.onTokenRefresh.listen(_register))
        ..add(_messaging.onForegroundMessage.listen(_onForegroundMessage))
        ..add(_messaging.onMessageOpened.listen(_openAlerts));

      await _register(await _messaging.getToken());

      final launchedBy = await _messaging.getInitialMessage();
      if (launchedBy != null) _openAlerts(launchedBy);
    } catch (error) {
      debugPrint('Push: could not start ($error).');
    } finally {
      _starting = false;
    }
  }

  /// Stops listening and marks push inactive. Does not tell the server.
  void stop() {
    _cancelListeners();
    _setActive(false);
  }

  void _cancelListeners() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
    _registeredToken = null;
  }

  /// For sign-out, while the session is still valid. Bounded so signing out
  /// offline is never held up by it.
  Future<void> unregisterCurrentDevice() async {
    final token = _registeredToken;
    stop();
    if (!_messaging.isAvailable) return;

    try {
      if (token != null) {
        await _ref.read(deviceApiProvider).unregisterToken(token).timeout(const Duration(seconds: 5));
      }
    } catch (error) {
      debugPrint('Push: could not unregister on the server ($error).');
    }
    try {
      await _messaging.deleteToken().timeout(const Duration(seconds: 5));
    } catch (error) {
      debugPrint('Push: could not delete the local token ($error).');
    }
  }

  Future<void> _register(String? token) async {
    if (token == null || token.isEmpty) return;
    try {
      await _ref.read(deviceApiProvider).registerToken(token, platform: _ref.read(pushPlatformProvider));
      _registeredToken = token;
      _setActive(true);
    } catch (error) {
      // Offline or the server is asleep. Stay inactive so the poll keeps
      // notifying; the next launch (or a token refresh) registers again.
      debugPrint('Push: could not register this device ($error).');
      _setActive(false);
    }
  }

  Future<void> _onForegroundMessage(PushMessage message) async {
    final id = message.announcementId;
    if (message.isAnnouncement && id != null) {
      try {
        await _ref.read(notificationServiceProvider).showPushAnnouncement(
              announcementId: id,
              title: message.title ?? 'New announcement',
              body: message.body ?? '',
              isEmergency: message.isEmergency,
            );
      } catch (error) {
        debugPrint('Push: could not show the notification ($error).');
      }
    }
    _ref.invalidate(announcementsProvider);
  }

  void _openAlerts(PushMessage message) {
    _ref.read(selectedTabProvider.notifier).state = AppTab.alerts;
    _ref.invalidate(announcementsProvider);
  }

  void _setActive(bool active) {
    final notifier = _ref.read(pushActiveProvider.notifier);
    if (notifier.state != active) notifier.state = active;
  }
}
