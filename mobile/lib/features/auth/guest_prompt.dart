import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'session_controller.dart';

/// Leaves guest mode for the sign-in screen. AppRoot's gate swaps the
/// GuestShell for SignInScreen; any screen a guest pushed on top (a club's
/// detail page, say) is popped so the sign-in screen is what they see.
void leaveGuestMode(BuildContext context, WidgetRef ref) {
  Navigator.of(context).popUntil((route) => route.isFirst);
  ref.read(guestModeProvider.notifier).leave();
}

/// For account-only actions (RSVP, joining a club). Returns true when someone
/// is signed in. For a guest it explains that [action] needs an account,
/// offers to sign in, and returns false, so the caller sends no request.
Future<bool> ensureSignedIn(BuildContext context, WidgetRef ref, {required String action}) async {
  if (ref.read(sessionControllerProvider).valueOrNull != null) return true;

  final signIn = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Sign in to continue'),
      content: Text('You need a Campus Companion account to $action. Guests can browse, but not take part.'),
      actions: [
        TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Not now')),
        FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Sign in')),
      ],
    ),
  );
  if (signIn == true && context.mounted) leaveGuestMode(context, ref);
  return false;
}
