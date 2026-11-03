import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_exception.dart';
import '../../core/providers/core_providers.dart';
import '../../core/services/push_coordinator.dart';
import '../../data/models/notification_preferences.dart';
import '../auth/session_controller.dart';

/// The user's push on/off setting, held on the server so it applies to every
/// device they are signed in on. Changes show immediately and are put back if
/// the server rejects them (same approach as the Clubs join button).
final pushSettingsProvider =
    AsyncNotifierProvider.autoDispose<PushSettingsController, NotificationPreferences>(PushSettingsController.new);

class PushSettingsController extends AutoDisposeAsyncNotifier<NotificationPreferences> {
  @override
  Future<NotificationPreferences> build() => ref.watch(deviceApiProvider).fetchPreferences();

  /// Sets the preference. If the request fails the previous value is restored
  /// and the error is rethrown so the caller can tell the user.
  Future<void> setEnabled(bool enabled) async {
    final previous = state.valueOrNull;
    if (previous == null || previous.pushEnabled == enabled) return;

    final api = ref.read(deviceApiProvider);
    final link = ref.keepAlive(); // survive the screen closing mid-request
    state = AsyncData(previous.copyWith(pushEnabled: enabled));
    try {
      state = AsyncData(await api.setPushEnabled(enabled));
    } catch (_) {
      state = AsyncData(previous);
      rethrow;
    } finally {
      link.close();
    }
  }
}

/// The "Push notifications" switch at the top of the Alerts tab. Shown only
/// when push is set up in this build and the setting could be loaded, so
/// today's app (no Firebase) looks exactly as it did.
class PushSettingsTile extends ConsumerWidget {
  const PushSettingsTile({super.key});

  Future<void> _toggle(BuildContext context, WidgetRef ref, bool enabled) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(pushSettingsProvider.notifier).setEnabled(enabled);
    } catch (error) {
      messenger
        ..removeCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error is ApiException ? error.message : 'Could not update the setting.')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(pushMessagingProvider).isAvailable) return const SizedBox.shrink();
    // The setting belongs to an account; a guest has none to load it from.
    if (ref.watch(sessionControllerProvider).valueOrNull == null) return const SizedBox.shrink();

    final settings = ref.watch(pushSettingsProvider).valueOrNull;
    if (settings == null) return const SizedBox.shrink(); // loading, or the server is unreachable

    final active = ref.watch(pushActiveProvider);
    final subtitle = !settings.pushEnabled
        ? 'Off. You will only see alerts inside the app.'
        : active
            ? 'Campus alerts reach you even when the app is closed.'
            : 'Not active on this device yet. Allow notifications for this app in your phone settings.';

    return SwitchListTile(
      secondary: const Icon(Icons.notifications_active_outlined),
      title: const Text('Push notifications'),
      subtitle: Text(subtitle),
      value: settings.pushEnabled,
      onChanged: (value) => _toggle(context, ref, value),
    );
  }
}
