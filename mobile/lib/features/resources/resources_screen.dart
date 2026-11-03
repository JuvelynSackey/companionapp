import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/campus_companion_theme.dart';
import '../../data/models/institution_profile.dart';
import '../../data/models/resource_models.dart';
import '../../widgets/campus_card_tile.dart';
import '../../widgets/demo_data_banner.dart';
import '../onboarding/institution_controller.dart';
import '../quizzes/quizzes_screen.dart';
import 'resources_providers.dart';

Color _occupancyColor(BuildContext context, SeatOccupancyLevel level) {
  switch (level) {
    case SeatOccupancyLevel.low:
      return Colors.green.shade600;
    case SeatOccupancyLevel.moderate:
      return Colors.amber.shade700;
    case SeatOccupancyLevel.high:
      return Colors.orange.shade800;
    case SeatOccupancyLevel.full:
      return Theme.of(context).colorScheme.error;
  }
}

String _occupancyLabel(SeatOccupancyLevel level) {
  switch (level) {
    case SeatOccupancyLevel.low:
      return 'Plenty of seats';
    case SeatOccupancyLevel.moderate:
      return 'Filling up';
    case SeatOccupancyLevel.high:
      return 'Nearly full';
    case SeatOccupancyLevel.full:
      return 'Full';
  }
}

class ResourcesScreen extends StatelessWidget {
  const ResourcesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Resources'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Libraries'),
              Tab(text: 'Past Papers'),
              Tab(text: 'Portals'),
              Tab(text: 'Documents'),
              Tab(text: 'Quizzes'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [_LibrariesTab(), _PastPapersTab(), _PortalsTab(), _DocumentsTab(), QuizzesTab()],
        ),
      ),
    );
  }
}

class _LibrariesTab extends StatelessWidget {
  const _LibrariesTab();

  @override
  Widget build(BuildContext context) {
    final campus = Theme.of(context).campusTheme;
    return Column(children: [
      const DemoDataBanner('Sample libraries and seat counts, not live occupancy.'),
      Expanded(child: _librariesList(campus)),
    ]);
  }

  Widget _librariesList(CampusCompanionTheme campus) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: ResourceFixtures.libraries.length,
      itemBuilder: (context, index) {
        final lib = ResourceFixtures.libraries[index];
        final color = _occupancyColor(context, lib.occupancyLevel);
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: campus.cardDecoration(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(lib.name, style: Theme.of(context).textTheme.titleMedium)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
                    child: Text(_occupancyLabel(lib.occupancyLevel), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(lib.campusZone, style: TextStyle(color: campus.textMuted, fontSize: 12)),
              const SizedBox(height: 8),
              Text(lib.description),
              const SizedBox(height: 8),
              Text('${lib.availableSeats} / ${lib.totalCapacity} seats available', style: TextStyle(fontWeight: FontWeight.bold, color: color)),
              Text(
                'Weekdays: ${lib.openingHoursWeekdays}\nWeekends: ${lib.openingHoursWeekends}',
                style: TextStyle(color: campus.textMuted, fontSize: 12),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PastPapersTab extends StatelessWidget {
  const _PastPapersTab();

  @override
  Widget build(BuildContext context) {
    final campus = Theme.of(context).campusTheme;
    return Column(children: [
      const DemoDataBanner('A sample list of past papers built into the app. To turn a real past paper into a quiz, use the Quizzes tab.'),
      Expanded(child: _pastPapersList(campus)),
    ]);
  }

  Widget _pastPapersList(CampusCompanionTheme campus) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: ResourceFixtures.pastPapers.length,
      itemBuilder: (context, index) {
        final paper = ResourceFixtures.pastPapers[index];
        return CampusCardTile(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: campus.cardDecoration(),
          radius: campus.cardRadius,
          child: ListTile(
            leading: CircleAvatar(backgroundColor: campus.accentGlow.withValues(alpha: 0.15), child: Icon(Icons.description_outlined, color: campus.accentGlow)),
            title: Text('${paper.courseCode} · ${paper.title}'),
            subtitle: Text('${paper.courseTitle} · ${paper.year}\n${paper.summaryText}', style: TextStyle(color: campus.textMuted)),
            isThreeLine: true,
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: campus.accentGlow.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
              child: Text(paper.fileType, style: TextStyle(color: campus.accentGlow, fontWeight: FontWeight.bold, fontSize: 11)),
            ),
          ),
        );
      },
    );
  }
}

class _PortalsTab extends ConsumerWidget {
  const _PortalsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final institution = ref.watch(institutionControllerProvider);
    final campus = Theme.of(context).campusTheme;
    final portals = institution.portals;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: portals.length,
      itemBuilder: (context, index) {
        final portal = portals[index];
        return CampusCardTile(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: campus.cardDecoration(),
          radius: campus.cardRadius,
          child: ListTile(
            // Institution color kept here deliberately — this is a per-school
            // branding badge (which university this portal belongs to), the
            // one surface type the design system still reserves for it.
            leading: CircleAvatar(backgroundColor: institution.primaryColor, child: const Icon(Icons.link, color: Colors.white)),
            title: Text(portal.name),
            subtitle: Text('${portal.category}\n${portal.description}', style: TextStyle(color: campus.textMuted)),
            isThreeLine: true,
            trailing: Icon(Icons.open_in_new, color: campus.accentGlow),
            onTap: () => _openPortal(context, portal),
          ),
        );
      },
    );
  }

  Future<void> _openPortal(BuildContext context, InstitutionPortal portal) async {
    final uri = Uri.tryParse(portal.url);
    if (uri == null || !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not open ${portal.name}')));
      }
    }
  }
}

/// Academic Calendar + Student Handbook (both static reference content) and
/// Document Requests (transcript / proof of registration). Requesting a
/// document only logs a tracked reference number — see DocumentType's doc
/// comment in resource_models.dart for why this app never fabricates the
/// official document itself.
class _DocumentsTab extends StatelessWidget {
  const _DocumentsTab();

  @override
  Widget build(BuildContext context) {
    final campus = Theme.of(context).campusTheme;
    return Column(children: [
      const DemoDataBanner(
        'Document requests are only saved on this phone. Nothing is sent to Academic Affairs: '
        "apply through your institution's official portal.",
      ),
      Expanded(child: _documentsList(context, campus)),
    ]);
  }

  Widget _documentsList(BuildContext context, CampusCompanionTheme campus) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Document Requests', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        const _DocumentRequestCard(type: DocumentType.transcript),
        const SizedBox(height: 8),
        const _DocumentRequestCard(type: DocumentType.proofOfRegistration),
        const SizedBox(height: 24),
        Text('Academic Calendar', style: Theme.of(context).textTheme.titleMedium),
        Text(
          'Sample dates — confirm the official calendar on your institution\'s portal.',
          style: TextStyle(color: campus.textMuted, fontSize: 12),
        ),
        const SizedBox(height: 8),
        for (final entry in ResourceFixtures.academicCalendar)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: campus.cardDecoration(),
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.event_outlined, color: campus.accentGlow, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entry.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(entry.dateRange, style: TextStyle(color: campus.accentGlow, fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(entry.description, style: TextStyle(color: campus.textMuted, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        Text('Student Handbook', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        // CampusCardTile, not a bare decorated Container: the ExpansionTiles'
        // ListTiles need a Material between them and the card's colour.
        CampusCardTile(
          decoration: campus.cardDecoration(),
          radius: campus.cardRadius,
          child: Column(
            children: [
              for (final section in ResourceFixtures.handbookSections)
                ExpansionTile(
                  title: Text(section.title),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  expandedAlignment: Alignment.centerLeft,
                  children: [Text(section.summary, style: TextStyle(color: campus.textMuted))],
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DocumentRequestCard extends ConsumerWidget {
  const _DocumentRequestCard({required this.type});
  final DocumentType type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final campus = Theme.of(context).campusTheme;
    final latest = ref.watch(documentRequestControllerProvider.select(
      (requests) => requests.where((r) => r.type == type).isEmpty
          ? null
          : (requests.where((r) => r.type == type).toList()..sort((a, b) => b.requestedAt.compareTo(a.requestedAt))).first,
    ));

    return CampusCardTile(
      decoration: campus.cardDecoration(),
      radius: campus.cardRadius,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(type.label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(type.description, style: TextStyle(color: campus.textMuted, fontSize: 12)),
          const SizedBox(height: 12),
          if (latest != null) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: campus.accentGlow.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Demo request saved · Ref: ${latest.referenceNumber}', style: TextStyle(color: campus.accentGlow, fontWeight: FontWeight.bold, fontSize: 12)),
                  Text(
                    'Saved on this phone ${DateFormat('MMM d, h:mm a').format(latest.requestedAt)}. Not sent to Academic Affairs.',
                    style: TextStyle(color: campus.textMuted, fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () async {
                final request = await ref.read(documentRequestControllerProvider.notifier).request(type);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Demo request saved on this phone (ref ${request.referenceNumber}). Nothing was sent.')),
                  );
                }
              },
              icon: const Icon(Icons.add_task_outlined, size: 18),
              label: Text(latest == null ? 'Request' : 'Request Another'),
            ),
          ),
        ],
      ),
    );
  }
}
