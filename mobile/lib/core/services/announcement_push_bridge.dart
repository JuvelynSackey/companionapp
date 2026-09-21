import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/announcement.dart';
import '../providers/core_providers.dart';

/// Foreground stand-in for real push notifications on new campus
/// announcements. No Firebase project is wired up for this app yet (no
/// google-services.json — see PROJECT_AUDIT.md), so there's no transport
/// that can wake the app in the background; this polls /api/announcements
/// while the app is open instead and hands anything new to
/// NotificationService.showAnnouncementNotification(), the same call a real
/// FCM onMessage/onBackgroundMessage handler would make. That split is the
/// actual point: swapping in real push later means replacing this timer
/// with an FCM listener, not touching how a payload becomes a notification.
///
/// The sync watermark itself (GET/PUT /api/announcements/sync-cursor) lives
/// server-side, not in local device storage — a per-device timestamp would
/// mean a student signed in on a second device, or reinstalling, gets a
/// fresh baseline and silently misses whatever was posted while only the
/// other device was online. A shared, monotonic announcement-id cursor on
/// the user's row fixes that: every device converges on the same "already
/// seen" boundary.
class AnnouncementPushBridge {
  AnnouncementPushBridge(this._ref);

  final Ref _ref;
  Timer? _timer;

  void start({Duration interval = const Duration(minutes: 5)}) {
    stop();
    unawaited(_checkForNew());
    _timer = Timer.periodic(interval, (_) => _checkForNew());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _checkForNew() async {
    final api = _ref.read(announcementApiProvider);

    int cursor;
    List<Announcement> announcements;
    try {
      cursor = await api.fetchSyncCursor();
      announcements = await api.fetch();
    } catch (_) {
      return; // offline/unreachable — the next tick will retry
    }

    if (announcements.isEmpty) return;
    final maxId = announcements.map((a) => a.announcementId).reduce((a, b) => a > b ? a : b);
    if (maxId <= cursor) return; // nothing new

    // cursor == 0 means "never synced" — baseline to the current max id
    // without notifying, so a fresh account/device isn't flooded with every
    // historical announcement the moment it first syncs.
    if (cursor > 0) {
      final service = _ref.read(notificationServiceProvider);
      for (final announcement in announcements) {
        if (announcement.announcementId > cursor) {
          await service.showAnnouncementNotification(announcement);
        }
      }
    }

    try {
      await api.updateSyncCursor(maxId);
    } catch (_) {
      // Next tick will retry with a recomputed maxId — worst case a student
      // sees a duplicate notification for something already shown once,
      // which showAnnouncementNotification's deterministic id then
      // collapses into a single OS notification anyway.
    }
  }
}

final announcementPushBridgeProvider = Provider<AnnouncementPushBridge>((ref) => AnnouncementPushBridge(ref));
