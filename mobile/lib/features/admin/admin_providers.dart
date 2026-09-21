import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/core_providers.dart';
import '../../data/models/app_user.dart';
import '../auth/session_controller.dart';

/// Whether the signed-in user is an admin. Drives what the UI shows; the
/// backend independently enforces the role on every admin route.
final isAdminProvider = Provider<bool>((ref) {
  return ref.watch(sessionControllerProvider).valueOrNull?.isAdmin ?? false;
});

/// State of the "create account" form's request. `AsyncData(null)` is idle,
/// `AsyncData(user)` is the account that was just created, and `AsyncError`
/// carries the backend's reason (e.g. duplicate email) for the UI to show.
final provisionUserProvider =
    AsyncNotifierProvider.autoDispose<ProvisionUserController, AppUser?>(ProvisionUserController.new);

class ProvisionUserController extends AutoDisposeAsyncNotifier<AppUser?> {
  // Synchronous on purpose: an async build would leave the provider in a
  // loading state at first, and provision() ignores calls while loading.
  @override
  AppUser? build() => null;

  /// Returns true if the account was created. Ignored (false) while a
  /// previous request is still running, so a double tap cannot create twice.
  Future<bool> provision({
    required String fullName,
    required String email,
    required String password,
    required String role,
  }) async {
    if (state.isLoading) return false;
    final api = ref.read(adminApiProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => api.provisionUser(fullName: fullName, email: email, password: password, role: role),
    );
    // Not hasValue: on failure Riverpod keeps the previous value alongside the error.
    return !state.hasError;
  }
}
