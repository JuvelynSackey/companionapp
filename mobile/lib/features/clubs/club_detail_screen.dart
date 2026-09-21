import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/models/campus_event.dart';
import '../../widgets/async_value_view.dart';
import '../events/events_providers.dart';
import 'club_membership_button.dart';
import 'clubs_providers.dart';

/// A club's profile plus its upcoming events. Reads the club from the shared
/// list (there is no GET /clubs/:id), so a join made here or on the list
/// shows up in both places at once. RSVPing stays on the Events screen.
class ClubDetailScreen extends ConsumerWidget {
  const ClubDetailScreen({super.key, required this.clubId});

  final int clubId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final club = ref.watch(clubByIdProvider(clubId));

    if (club == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Club')),
        body: const Center(child: Text('Club not found.')),
      );
    }

    final theme = Theme.of(context);
    final events = ref.watch(clubEventsProvider(club.name));

    return Scaffold(
      appBar: AppBar(title: Text(club.name, overflow: TextOverflow.ellipsis)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text(
                  club.name.substring(0, 1).toUpperCase(),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(club.name, style: theme.textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(
                      club.memberCount == 1 ? '1 member' : '${club.memberCount} members',
                      style: theme.textTheme.bodyMedium,
                    ),
                    if (club.isMember)
                      Text(
                        "You're a member",
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (club.description.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(club.description),
          ],
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: ClubMembershipButton(club: club, prominent: true),
          ),
          const SizedBox(height: 24),
          Text('Upcoming events', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          AsyncValueView<List<CampusEvent>>(
            value: events,
            onRetry: () => ref.invalidate(eventsProvider),
            data: (context, items) {
              if (items.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('No upcoming events from this club.'),
                );
              }
              return Column(children: [for (final event in items) _ClubEventTile(event: event)]);
            },
          ),
        ],
      ),
    );
  }
}

class _ClubEventTile extends StatelessWidget {
  const _ClubEventTile({required this.event});
  final CampusEvent event;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final when = DateFormat('EEE, MMM d · h:mm a').format(event.eventDate.toLocal());
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: ListTile(
        title: Text(event.title),
        subtitle: Text([when, if (event.location != null) event.location!].join(' · ')),
        trailing: Text('${event.attendeeCount} going', style: theme.textTheme.bodySmall),
      ),
    );
  }
}
