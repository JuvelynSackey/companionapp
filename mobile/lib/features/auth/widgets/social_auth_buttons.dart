import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/theme/landing_theme.dart';
import '../../onboarding/institution_controller.dart';
import '../../onboarding/institution_picker_screen.dart';
import '../session_controller.dart';

/// The Google / Guest row shared by WelcomeScreen and SignInScreen. Google is
/// wired to the real sign-in flow (see docs/google-sign-in.md for what's
/// needed to turn it on); until that is done in a build, tapping it says so
/// instead of silently doing nothing. Guest opens the GuestShell. There is no
/// Apple button: Apple sign-in is out of scope, and the app shows no button
/// for a sign-in method it does not have.
/// Shown when Google is tapped in a build where it isn't configured yet.
const googleNotEnabledMessage = "Google sign-in isn't switched on in this version yet. Use email and password.";

class SocialAuthButtons extends ConsumerWidget {
  const SocialAuthButtons({super.key});

  Future<void> _continueWithGoogle(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    await ref.read(sessionControllerProvider.notifier).loginWithGoogle();
    final state = ref.read(sessionControllerProvider);
    // A cancelled picker and "nothing happened yet" both land as data(null) —
    // neither is an error, so only hasError gets a message here.
    if (state.hasError) {
      final error = state.error;
      messenger
        ..removeCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error is ApiException ? error.message : 'Google sign-in failed.')));
    }
  }

  /// From SignInScreen the gate swaps straight to the GuestShell. From
  /// WelcomeScreen onboarding hasn't run yet (the gate checks it first), so
  /// the institution picker comes next, as it does for Google sign-in there.
  void _continueAsGuest(BuildContext context, WidgetRef ref) {
    ref.read(guestModeProvider.notifier).state = true;
    if (!ref.read(onboardingControllerProvider)) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const InstitutionPickerScreen()));
    }
  }

  void _googleNotEnabled(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..removeCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text(googleNotEnabledMessage)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final googleAvailable = ref.watch(googleAuthServiceProvider).isAvailable;
    final submitting = ref.watch(sessionControllerProvider).isLoading;

    return Column(
      children: [
        OutlinedButton.icon(
          style: LandingStyle.outlinedButtonStyle,
          icon: submitting
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: LandingColors.inkMuted),
                )
              : const _LetterBadge('G', color: Color(0xFF4285F4)),
          label: const Text('Continue with Google'),
          onPressed: submitting
              ? null
              : googleAvailable
                  ? () => _continueWithGoogle(context, ref)
                  : () => _googleNotEnabled(context),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          style: LandingStyle.outlinedButtonStyle,
          icon: const Icon(Icons.person_outline, size: 20),
          label: const Text('Continue as Guest'),
          onPressed: submitting ? null : () => _continueAsGuest(context, ref),
        ),
      ],
    );
  }
}

class _LetterBadge extends StatelessWidget {
  const _LetterBadge(this.letter, {required this.color});
  final String letter;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 20,
      width: 20,
      child: CircleAvatar(
        backgroundColor: color,
        child: Text(letter, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
