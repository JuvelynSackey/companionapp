import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_exception.dart';
import '../../core/providers/core_providers.dart';
import '../events/event_pass_controller.dart';
import '../events/events_providers.dart';
import 'admin_providers.dart';

/// Admin-only "delete this event" button with a confirmation step. Renders
/// nothing for anyone else. After a delete it refreshes the events list and
/// drops any RSVP pass this device holds for the event.
class DeleteEventButton extends ConsumerWidget {
  const DeleteEventButton({super.key, required this.eventId, required this.eventTitle});

  final int eventId;
  final String eventTitle;

  Future<void> _confirmAndDelete(BuildContext context) async {
    // Captured up front: the card can be rebuilt away (e.g. a pull-to-refresh)
    // while the dialog or request is pending, and a widget's own `ref` must
    // not be used after that.
    final messenger = ScaffoldMessenger.of(context);
    final container = ProviderScope.containerOf(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete event?'),
        content: Text('"$eventTitle" will be removed for everyone, along with all RSVPs. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await container.read(adminApiProvider).deleteEvent(eventId);
      await container.read(eventPassControllerProvider.notifier).revoke(eventId);
      container.invalidate(eventsProvider);
      messenger
        ..removeCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Deleted "$eventTitle".')));
    } catch (e) {
      // A 404 means it was already deleted elsewhere; the list is stale either way.
      if (e is ApiException && e.statusCode == 404) container.invalidate(eventsProvider);
      messenger
        ..removeCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(describeApiError(e))));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(isAdminProvider)) return const SizedBox.shrink();

    return IconButton(
      icon: const Icon(Icons.delete_outline),
      tooltip: 'Delete event',
      color: Theme.of(context).colorScheme.error,
      onPressed: () => _confirmAndDelete(context),
    );
  }
}
