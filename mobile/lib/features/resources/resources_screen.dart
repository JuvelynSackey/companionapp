import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/campus_companion_theme.dart';
import '../../data/models/institution_profile.dart';
import '../../data/models/resource_models.dart';
import '../../widgets/campus_card_tile.dart';
import '../onboarding/institution_controller.dart';

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
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Resources'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Libraries'),
              Tab(text: 'Past Papers'),
              Tab(text: 'Portals'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [_LibrariesTab(), _PastPapersTab(), _PortalsTab()],
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
