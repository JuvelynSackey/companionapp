import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/core_providers.dart';
import '../../core/services/push_coordinator.dart';
import '../../data/models/app_user.dart';

/// True right after a mid-session or launch-time 401 clears the token — lets
/// the UI show "your session expired" instead of a plain sign-in screen.
/// Reset on every successful login/register/signOut so a fresh sign-in
/// doesn't carry a stale "expired" banner into the next session.
final sessionExpiredProvider = StateProvider<bool>((ref) => false);

/// True while someone is browsing without an account ("Continue as Guest").
/// AppRoot shows the GuestShell for it whenever nobody is signed in. Saved on
/// the device, so a guest who closes the app comes back to the guest shell
/// rather than the sign-in screen. Every successful sign-in, a sign-out, and
/// the guest's own "Sign in" clear it.
class GuestModeController extends Notifier<bool> {
  @override
  bool build() => ref.watch(localPrefsProvider).isGuestMode;

  Future<void> enter() => _set(true);
  Future<void> leave() => _set(false);

  /// The screen changes at once; the saved copy follows.
  Future<void> _set(bool value) async {
    state = value;
    await ref.read(localPrefsProvider).setGuestMode(value);
  }
}

final guestModeProvider = NotifierProvider<GuestModeController, bool>(GuestModeController.new);

/// Holds the current signed-in user (or null). `null` while restoring the
/// session is not distinguishable from "signed out" here — callers should
/// use isLoading (AsyncValue) on first launch to show a splash state, and
/// sessionExpiredProvider to distinguish "never signed in" from "was signed
/// in, token rejected".
class SessionController extends AsyncNotifier<AppUser?> {
  @override
  Future<AppUser?> build() async {
    final result = await ref.watch(authRepositoryProvider).restoreSession();
    // Only ever flips this to true here — never back to false. A rebuild
    // triggered by ApiClient.onSessionExpired (mid-session 401) already set
    // it true and cleared the token, so restoreSession sees "no token" and
    // would otherwise report expired:false, clobbering the flag we just set.
    if (result.expired) ref.read(sessionExpiredProvider.notifier).state = true;
    return result.user;
  }

  /// Runs a sign-in action while keeping the current (signed-out) value under
  /// the loading and error states. AppRoot's gate only shows its full-page
  /// error/spinner when there is no value at all (a failed session restore);
  /// a failed login keeps a value, so the form stays on screen with its error.
  Future<void> _attempt(Future<AppUser?> Function() action) async {
    final previous = state;
    state = const AsyncLoading<AppUser?>().copyWithPrevious(previous);
    state = (await AsyncValue.guard(action)).copyWithPrevious(previous);
    if (state.valueOrNull != null) await ref.read(guestModeProvider.notifier).leave();
  }

  Future<void> login({required String email, required String password}) async {
    await _attempt(() => ref.read(authRepositoryProvider).login(email: email, password: password));
    if (!state.hasError) ref.read(sessionExpiredProvider.notifier).state = false;
  }

  /// If the person cancels the Google account picker, this leaves [state] as
  /// `AsyncValue.data(null)` — the same "not signed in" state as before the
  /// tap, not an error, so the UI shows nothing extra and just stays put.
  Future<void> loginWithGoogle() async {
    await _attempt(() => ref.read(authRepositoryProvider).loginWithGoogle());
    if (!state.hasError && state.value != null) ref.read(sessionExpiredProvider.notifier).state = false;
  }

  Future<void> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    await _attempt(
      () => ref.read(authRepositoryProvider).register(fullName: fullName, email: email, password: password),
    );
    if (!state.hasError) ref.read(sessionExpiredProvider.notifier).state = false;
  }

  Future<void> signOut() async {
    // Before the token is cleared: unregistering the device needs the session.
    await ref.read(pushCoordinatorProvider).unregisterCurrentDevice();
    await ref.read(authRepositoryProvider).signOut();
    ref.read(sessionExpiredProvider.notifier).state = false;
    await ref.read(guestModeProvider.notifier).leave();
    state = const AsyncValue.data(null);
  }
}

final sessionControllerProvider = AsyncNotifierProvider<SessionController, AppUser?>(
  SessionController.new,
);
