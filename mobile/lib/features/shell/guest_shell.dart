import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../alerts/alerts_screen.dart';
import '../auth/guest_prompt.dart';
import '../clubs/clubs_screen.dart';
import '../events/events_screen.dart';
import '../locations/locations_screen.dart';

/// What a guest ("Continue as Guest") can browse: the campus-wide feeds the
/// backend serves without a token (announcements, events, clubs, the map).
/// Personal features (timetable, exams, grades, Digital ID, the assistant)
/// are not offered; account-only actions on these screens ask the guest to
/// sign in instead (see ensureSignedIn).
final guestTabProvider = StateProvider<int>((ref) => 0);

class GuestShell extends ConsumerWidget {
  const GuestShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(guestTabProvider);

    return Scaffold(
      body: IndexedStack(
        index: index,
        children: const [
          _GuestAlertsTab(),
          EventsScreen(),
          ClubsScreen(),
          LocationsScreen(),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _GuestBanner(),
          NavigationBar(
            selectedIndex: index,
            onDestinationSelected: (i) => ref.read(guestTabProvider.notifier).state = i,
            destinations: const [
              NavigationDestination(icon: Icon(Icons.notifications_outlined), selectedIcon: Icon(Icons.notifications), label: 'Alerts'),
              NavigationDestination(icon: Icon(Icons.event_outlined), selectedIcon: Icon(Icons.event), label: 'Events'),
              NavigationDestination(icon: Icon(Icons.groups_outlined), selectedIcon: Icon(Icons.groups), label: 'Clubs'),
              NavigationDestination(icon: Icon(Icons.map_outlined), selectedIcon: Icon(Icons.map), label: 'Map'),
            ],
          ),
        ],
      ),
    );
  }
}

/// AlertsScreen has no app bar of its own (AppShell supplies one), so the
/// guest tab adds it.
class _GuestAlertsTab extends StatelessWidget {
  const _GuestAlertsTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Campus Alerts')),
      body: const AlertsScreen(),
    );
  }
}

class _GuestBanner extends ConsumerWidget {
  const _GuestBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
        child: Row(
          children: [
            Icon(Icons.person_outline, size: 18, color: scheme.onPrimaryContainer),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                "You're browsing as a guest",
                style: TextStyle(color: scheme.onPrimaryContainer, fontWeight: FontWeight.w600),
              ),
            ),
            TextButton(
              onPressed: () => leaveGuestMode(context, ref),
              child: const Text('Sign in'),
            ),
          ],
        ),
      ),
    );
  }
}
