import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/theme/landing_theme.dart';
import '../session_controller.dart';

/// The Google / Apple / Guest row shared by WelcomeScreen and SignInScreen.
/// Google is wired to the real sign-in flow (see docs/google-sign-in.md for
/// what's needed to turn it on); Apple and Guest are not built yet — see
/// PROJECT_AUDIT.md. The labels carry no "(Coming soon)" suffix, but tapping
/// a button whose feature isn't available still shows a short notice rather
/// than silently doing nothing.
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

  void _comingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context)
      ..removeCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$feature is coming soon.')));
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
                  : () => _comingSoon(context, 'Google sign-in'),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          style: LandingStyle.outlinedButtonStyle,
          icon: const Icon(Icons.apple, size: 20),
          label: const Text('Continue with Apple'),
          onPressed: () => _comingSoon(context, 'Apple sign-in'),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          style: LandingStyle.outlinedButtonStyle,
          icon: const Icon(Icons.person_outline, size: 20),
          label: const Text('Continue as Guest'),
          onPressed: () => _comingSoon(context, 'Guest mode'),
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
