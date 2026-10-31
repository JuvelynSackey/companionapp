import 'package:flutter/material.dart';
import '../../analytics/analytics_screen.dart';
import '../../assistant/assistant_screen.dart';
import '../../clubs/clubs_screen.dart';
import '../../events/events_screen.dart';
import '../../locations/locations_screen.dart';
import '../../tutor/tutor_screen.dart';

class QuickAccessItem {
  const QuickAccessItem(this.label, this.icon, this.color, this.builder);
  final String label;
  final IconData icon;
  final Color color;
  final WidgetBuilder builder;
}

final quickAccessItems = <QuickAccessItem>[
  QuickAccessItem('Campus map', Icons.map_outlined, const Color(0xFF00897B), (_) => const LocationsScreen()),
  QuickAccessItem('Events', Icons.event_available_outlined, const Color(0xFFEF6C00), (_) => const EventsScreen()),
  QuickAccessItem('Clubs', Icons.groups_outlined, const Color(0xFFD81B60), (_) => const ClubsScreen()),
  QuickAccessItem('Grades & GPA', Icons.insights_outlined, const Color(0xFF2E7D32), (_) => const AnalyticsScreen()),
  QuickAccessItem('AI Assistant', Icons.auto_awesome_outlined, const Color(0xFF7E57C2), (_) => const AssistantScreen()),
  QuickAccessItem('AI Tutor', Icons.school_outlined, const Color(0xFF1E88E5), (_) => const TutorScreen()),
];

/// Labelled shortcuts to the screens that aren't bottom-nav tabs. They used
/// to be six unlabelled icons in the app bar, which also squeezed the screen
/// title down to "Da…" on a phone.
class QuickAccessGrid extends StatelessWidget {
  const QuickAccessGrid({super.key, this.onOpen});

  /// Defaults to pushing the item's screen; tests pass a recorder instead.
  final void Function(BuildContext context, QuickAccessItem item)? onOpen;

  void _open(BuildContext context, QuickAccessItem item) {
    if (onOpen != null) return onOpen!(context, item);
    Navigator.of(context).push(MaterialPageRoute(builder: item.builder));
  }

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.05,
      children: [for (final item in quickAccessItems) _QuickTile(item: item, onTap: () => _open(context, item))],
    );
  }
}

class _QuickTile extends StatelessWidget {
  const _QuickTile({required this.item, required this.onTap});
  final QuickAccessItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: scheme.outlineVariant),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: item.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
                child: Icon(item.icon, color: item.color, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                item.label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
