import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_exception.dart';
import '../../data/models/club.dart';
import '../auth/guest_prompt.dart';
import 'clubs_providers.dart';

/// Join / Leave button shared by the club list and the club detail screen.
/// Shows the optimistic state immediately, is disabled while its request is
/// in flight, and reports a failed request in a SnackBar.
class ClubMembershipButton extends ConsumerWidget {
  const ClubMembershipButton({super.key, required this.club, this.prominent = false});

  final Club club;

  /// Filled button for the detail screen; outlined for list cards.
  final bool prominent;

  Future<void> _toggle(BuildContext context, WidgetRef ref) async {
    if (!await ensureSignedIn(context, ref, action: 'join clubs')) return;
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(clubsProvider.notifier).toggleMembership(club.clubId);
    } catch (e) {
      final message = e is ApiException ? e.message : 'Something went wrong. Please try again.';
      messenger.showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(clubMembershipPendingProvider).contains(club.clubId);
    final label = Text(club.isMember ? 'Leave' : 'Join');
    final onPressed = pending ? null : () => _toggle(context, ref);

    if (prominent) {
      return club.isMember
          ? OutlinedButton(onPressed: onPressed, child: label)
          : FilledButton(onPressed: onPressed, child: label);
    }
    return club.isMember
        ? OutlinedButton(onPressed: onPressed, child: label)
        : FilledButton.tonal(onPressed: onPressed, child: label);
  }
}
