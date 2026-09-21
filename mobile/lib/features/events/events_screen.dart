import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/providers/core_providers.dart';
import '../../data/models/campus_event.dart';
import '../../data/models/event_pass.dart';
import '../../data/models/student_identity.dart';
import '../../widgets/async_value_view.dart';
import '../auth/session_controller.dart';
import '../clubs/clubs_screen.dart';
import '../onboarding/institution_controller.dart';
import 'create_event_dialog.dart';
import 'event_pass_controller.dart';
import 'event_pass_dialog.dart';
import 'events_providers.dart';

class EventsScreen extends ConsumerWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(eventsProvider);
    final canCreateEvents = ref.watch(sessionControllerProvider).valueOrNull?.canCreateEvents ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Events'),
        actions: [
          IconButton(
            icon: const Icon(Icons.groups_outlined),
            tooltip: 'Clubs',
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ClubsScreen())),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(eventsProvider.future),
        child: AsyncValueView<List<CampusEvent>>(
          value: events,
          onRetry: () => ref.invalidate(eventsProvider),
          data: (context, items) {
            if (items.isEmpty) {
              return ListView(
                children: const [
                  Padding(padding: EdgeInsets.all(32), child: Center(child: Text('No upcoming events.'))),
                ],
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (context, index) => _EventCard(event: items[index]),
            );
          },
        ),
      ),
      floatingActionButton: canCreateEvents
          ? FloatingActionButton(
              heroTag: 'events_fab',
              onPressed: () async {
                final created = await showDialog<bool>(context: context, builder: (_) => const CreateEventDialog());
                if (created == true) ref.invalidate(eventsProvider);
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

class _EventCard extends ConsumerStatefulWidget {
  const _EventCard({required this.event});
  final CampusEvent event;

  @override
  ConsumerState<_EventCard> createState() => _EventCardState();
}

class _EventCardState extends ConsumerState<_EventCard> {
  bool _submitting = false;

  Future<void> _toggleRegistration() async {
    setState(() => _submitting = true);
    try {
      if (widget.event.isRegistered) {
        await ref.read(eventApiProvider).cancelRegistration(widget.event.eventId);
        await ref.read(eventPassControllerProvider.notifier).revoke(widget.event.eventId);
      } else {
        await ref.read(eventApiProvider).register(widget.event.eventId);
        await _issuePass();
      }
      ref.invalidate(eventsProvider);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _issuePass() async {
    final user = ref.read(sessionControllerProvider).valueOrNull;
    if (user == null) return;
    final institution = ref.read(institutionControllerProvider);
    final localProfile = ref.read(localProfileControllerProvider);
    final pass = await ref.read(eventPassControllerProvider.notifier).generate(
          event: widget.event,
          studentName: user.fullName,
          studentId: displayStudentId(user.userId, institution, localProfile),
        );
    if (mounted) _showPass(pass);
  }

  void _showPass(EventPass pass) => showDialog(context: context, builder: (_) => EventPassDialog(pass: pass));

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(event.title, style: Theme.of(context).textTheme.titleMedium)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    DateFormat('MMM d').format(event.eventDate.toLocal()),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            if (event.description.isNotEmpty) Text(event.description),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                Text(DateFormat('EEE, MMM d · h:mm a').format(event.eventDate.toLocal()), style: Theme.of(context).textTheme.bodySmall),
                if (event.location != null) Text('📍 ${event.location}', style: Theme.of(context).textTheme.bodySmall),
                if (event.clubName != null) Text('🎓 ${event.clubName}', style: Theme.of(context).textTheme.bodySmall),
                Text('${event.attendeeCount} attending', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: _submitting
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (event.isRegistered) ...[
                          Consumer(
                            builder: (context, ref, _) {
                              final pass = ref.watch(eventPassControllerProvider)[event.eventId];
                              if (pass == null) return const SizedBox.shrink();
                              return TextButton.icon(
                                icon: const Icon(Icons.confirmation_number_outlined, size: 18),
                                label: const Text('View Pass'),
                                onPressed: () => _showPass(pass),
                              );
                            },
                          ),
                          const SizedBox(width: 4),
                        ],
                        OutlinedButton(
                          onPressed: _toggleRegistration,
                          child: Text(event.isRegistered ? 'Cancel RSVP' : 'RSVP'),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
