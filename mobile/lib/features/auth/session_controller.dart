import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/core_providers.dart';
import '../../data/models/app_user.dart';

/// True right after a mid-session or launch-time 401 clears the token — lets
/// the UI show "your session expired" instead of a plain sign-in screen.
/// Reset on every successful login/register/signOut so a fresh sign-in
/// doesn't carry a stale "expired" banner into the next session.
final sessionExpiredProvider = StateProvider<bool>((ref) => false);

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

  Future<void> login({required String email, required String password}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).login(email: email, password: password),
    );
    if (state.hasValue) ref.read(sessionExpiredProvider.notifier).state = false;
  }

  Future<void> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).register(fullName: fullName, email: email, password: password),
    );
    if (state.hasValue) ref.read(sessionExpiredProvider.notifier).state = false;
  }

  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).signOut();
    ref.read(sessionExpiredProvider.notifier).state = false;
    state = const AsyncValue.data(null);
  }
}

final sessionControllerProvider = AsyncNotifierProvider<SessionController, AppUser?>(
  SessionController.new,
);
