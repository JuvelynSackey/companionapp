import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/campus_companion_theme.dart';
import '../../data/models/institution_profile.dart';
import '../../widgets/campus_card_tile.dart';
import '../onboarding/institution_controller.dart';
import '../quizzes/quizzes_screen.dart';

/// The institution's official portals and documents, and the quizzes. Tabs
/// that could only show sample content (library seat counts, a past-paper
/// list, an academic calendar, handbook summaries and document requests that
/// were never sent anywhere) were removed rather than kept as demo data; the
/// official sources are linked from Portals instead.
class ResourcesScreen extends StatelessWidget {
  const ResourcesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Resources'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Portals'),
              Tab(text: 'Quizzes'),
            ],
          ),
        ),
        body: const TabBarView(children: [_PortalsTab(), QuizzesTab()]),
      ),
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
            leading: CircleAvatar(
              backgroundColor: institution.primaryColor,
              child: Icon(portal.category == officialDocumentsCategory ? Icons.description_outlined : Icons.link, color: Colors.white),
            ),
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
