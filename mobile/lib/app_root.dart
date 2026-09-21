import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/providers/core_providers.dart';
import 'core/services/announcement_push_bridge.dart';
import 'core/services/push_coordinator.dart';
import 'core/theme/app_theme.dart';
import 'data/models/app_user.dart';
import 'features/auth/auth_status.dart';
import 'features/auth/session_controller.dart';
import 'features/auth/sign_in_screen.dart';
import 'features/onboarding/institution_controller.dart';
import 'features/onboarding/institution_picker_screen.dart';
import 'features/shell/app_shell.dart';
import 'widgets/async_value_view.dart';

class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Campus Companion',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: const _RootGate(),
    );
  }
}

class _RootGate extends ConsumerWidget {
  const _RootGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboardingCompleted = ref.watch(onboardingControllerProvider);
    if (!onboardingCompleted) {
      return const InstitutionPickerScreen();
    }

    final session = ref.watch(sessionControllerProvider);

    // Real push (when configured): register this device while signed in.
    // stop() only stops listening; signing out unregisters the device on the
    // server first (SessionController.signOut), and an expired session cannot.
    // The listener handles changes (its callbacks never run during a build, so
    // stop() may safely change state); start() is idempotent, so calling it
    // below also covers a session that was already restored at launch.
    ref.listen<AsyncValue<AppUser?>>(sessionControllerProvider, (previous, next) {
      if (next.valueOrNull != null) {
        ref.read(pushCoordinatorProvider).start();
      } else if (next.hasValue) {
        ref.read(pushCoordinatorProvider).stop();
      }
    });

    // Starts/stops the announcement push bridge (see its doc comment) as the
    // session resolves — covers both a fresh sign-in and a restored token,
    // since both land here as session.valueOrNull becoming non-null.
    final signedInUser = session.valueOrNull;
    if (signedInUser != null) {
      ref.read(pushCoordinatorProvider).start();
      ref.read(notificationServiceProvider).requestPermission();
      ref.read(announcementPushBridgeProvider).start();
    } else if (session.hasValue) {
      ref.read(announcementPushBridgeProvider).stop();
    }

    // A restore failure here means the backend couldn't be reached to
    // validate the token (not that the token was rejected — a 401 is
    // handled inside AuthRepository.restoreSession and surfaces as a plain
    // signed-out state, not an error) — so this offers a retry instead of
    // dumping the student at Sign In as if they'd been logged out.
    return Scaffold(
      body: AsyncValueView<AppUser?>(
        value: session,
        onRetry: () => ref.invalidate(sessionControllerProvider),
        data: (context, user) {
          final expired = ref.watch(sessionExpiredProvider);
          final status = user != null
              ? AuthStatus.authenticated
              : (expired ? AuthStatus.sessionExpired : AuthStatus.unauthenticated);

          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: switch (status) {
              AuthStatus.authenticated => const AppShell(key: ValueKey('shell')),
              AuthStatus.sessionExpired =>
                const SignInScreen(key: ValueKey('signin-expired'), showExpiredNotice: true),
              AuthStatus.unauthenticated || AuthStatus.initializing =>
                const SignInScreen(key: ValueKey('signin')),
            },
          );
        },
      ),
    );
  }
}
