import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/club.dart';
import '../../widgets/async_value_view.dart';
import '../auth/session_controller.dart';
import 'club_detail_screen.dart';
import 'club_membership_button.dart';
import 'clubs_providers.dart';

class ClubsScreen extends ConsumerWidget {
  const ClubsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filtered = ref.watch(filteredClubsProvider);
    final hasAnyClubs = ref.watch(clubsProvider).valueOrNull?.isNotEmpty ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('Clubs')),
      body: Column(
        children: [
          const _SearchAndFilters(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.refresh(clubsProvider.future),
              child: AsyncValueView<List<Club>>(
                value: filtered,
                onRetry: () => ref.invalidate(clubsProvider),
                data: (context, clubs) {
                  if (clubs.isEmpty) {
                    return ListView(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(32),
                          child: Center(
                            child: Text(hasAnyClubs ? 'No clubs match your search.' : 'No clubs yet.'),
                          ),
                        ),
                      ],
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: clubs.length,
                    itemBuilder: (context, index) => _ClubCard(club: clubs[index]),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchAndFilters extends ConsumerWidget {
  const _SearchAndFilters();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(clubFilterProvider);
    // A guest has no clubs, so "My clubs" would always be empty.
    final signedIn = ref.watch(sessionControllerProvider).valueOrNull != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        children: [
          TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search clubs',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (value) => ref.read(clubSearchQueryProvider.notifier).state = value,
          ),
          if (signedIn) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('All'),
                    selected: filter == ClubFilter.all,
                    onSelected: (_) => ref.read(clubFilterProvider.notifier).state = ClubFilter.all,
                  ),
                  ChoiceChip(
                    label: const Text('My clubs'),
                    selected: filter == ClubFilter.mine,
                    onSelected: (_) => ref.read(clubFilterProvider.notifier).state = ClubFilter.mine,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ClubCard extends StatelessWidget {
  const _ClubCard({required this.club});
  final Club club;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ClubDetailScreen(clubId: club.clubId)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(club.name, style: theme.textTheme.titleMedium)),
                  if (club.isMember) const _MemberBadge(),
                ],
              ),
              if (club.description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(club.description, maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.groups_outlined, size: 16, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    club.memberCount == 1 ? '1 member' : '${club.memberCount} members',
                    style: theme.textTheme.bodySmall,
                  ),
                  const Spacer(),
                  ClubMembershipButton(club: club),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MemberBadge extends StatelessWidget {
  const _MemberBadge();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: BorderRadius.circular(16)),
      child: Text(
        'Member',
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: scheme.onPrimaryContainer),
      ),
    );
  }
}
