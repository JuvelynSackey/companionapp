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
import 'features/auth/welcome_screen.dart';
import 'features/onboarding/institution_controller.dart';
import 'features/shell/app_shell.dart';
import 'features/shell/guest_shell.dart';
import 'widgets/async_value_view.dart';
import 'widgets/brand_splash.dart';

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
      // Signing in with Google here (WelcomeScreen) still lands back on this
      // gate afterward with onboarding still incomplete, so the institution
      // picker always runs once per device — see WelcomeScreen's doc comment.
      return const WelcomeScreen();
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

    Widget gate(BuildContext context, AppUser? user) {
      final expired = ref.watch(sessionExpiredProvider);
      final guest = ref.watch(guestModeProvider);
      final status = user != null
          ? AuthStatus.authenticated
          : (expired ? AuthStatus.sessionExpired : AuthStatus.unauthenticated);

      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: switch (status) {
          AuthStatus.authenticated => const AppShell(key: ValueKey('shell')),
          AuthStatus.sessionExpired => const SignInScreen(key: ValueKey('signin-expired'), showExpiredNotice: true),
          AuthStatus.unauthenticated || AuthStatus.initializing =>
            guest ? const GuestShell(key: ValueKey('guest')) : const SignInScreen(key: ValueKey('signin')),
        },
      );
    }

    // Once the session has a value, a loading or error state is a sign-in
    // attempt in progress or failed (SessionController keeps the previous value
    // for those), and the sign-in screen shows its own spinner and message.
    // Without a value, the restore at launch is still loading, or failed
    // because the backend couldn't be reached to validate the token (a 401 is
    // handled inside AuthRepository.restoreSession as a plain signed-out
    // state): that offers a retry rather than dumping the student at Sign In.
    return Scaffold(
      body: session.hasValue
          ? gate(context, session.valueOrNull)
          : session.isLoading
          ? const BrandSplash()
          : AsyncValueView<AppUser?>(
              value: session,
              onRetry: () => ref.invalidate(sessionControllerProvider),
              data: gate,
            ),
    );
  }
}
