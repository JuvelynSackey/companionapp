import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/providers/core_providers.dart';
import '../../data/models/announcement.dart';
import '../../widgets/async_value_view.dart';
import '../auth/session_controller.dart';
import 'alerts_providers.dart';
import 'broadcast_alert_dialog.dart';

Color _categoryColor(BuildContext context, String category) {
  final scheme = Theme.of(context).colorScheme;
  switch (category) {
    case 'emergency':
      return scheme.error;
    case 'academic':
      return Colors.blue.shade700;
    default:
      return scheme.primary;
  }
}

IconData _categoryIcon(String category) {
  switch (category) {
    case 'emergency':
      return Icons.warning_amber_rounded;
    case 'academic':
      return Icons.school_outlined;
    default:
      return Icons.campaign_outlined;
  }
}

class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final announcements = ref.watch(announcementsProvider);
    final isAdmin = ref.watch(sessionControllerProvider).valueOrNull?.isAdmin ?? false;
    final localPrefs = ref.watch(localPrefsProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(announcementsProvider.future),
        child: AsyncValueView<List<Announcement>>(
          value: announcements,
          onRetry: () => ref.invalidate(announcementsProvider),
          data: (context, items) {
            if (items.isEmpty) {
              return ListView(
                children: const [
                  Padding(padding: EdgeInsets.all(32), child: Center(child: Text('No alerts yet.'))),
                ],
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final isRead = localPrefs.readAnnouncementIds.contains(item.announcementId);
                final color = _categoryColor(context, item.category);
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                  ),
                  child: ListTile(
                    onTap: () async {
                      await localPrefs.markAnnouncementRead(item.announcementId);
                      ref.invalidate(localPrefsProvider);
                      if (context.mounted) {
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: Text(item.title),
                            content: Text(item.message),
                            actions: [
                              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
                              if (isAdmin)
                                TextButton(
                                  onPressed: () async {
                                    await ref.read(announcementApiProvider).delete(item.announcementId);
                                    ref.invalidate(announcementsProvider);
                                    if (context.mounted) Navigator.of(context).pop();
                                  },
                                  child: const Text('Delete'),
                                ),
                            ],
                          ),
                        );
                      }
                    },
                    leading: CircleAvatar(
                      backgroundColor: color.withValues(alpha: 0.15),
                      child: Icon(_categoryIcon(item.category), color: color),
                    ),
                    title: Text(
                      item.title,
                      style: TextStyle(fontWeight: isRead ? FontWeight.normal : FontWeight.bold),
                    ),
                    subtitle: Text(item.message, maxLines: 2, overflow: TextOverflow.ellipsis),
                    trailing: Text(DateFormat('MMM d').format(item.datePosted.toLocal()), style: Theme.of(context).textTheme.bodySmall),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              onPressed: () async {
                final broadcast = await showDialog<bool>(
                  context: context,
                  builder: (_) => const BroadcastAlertDialog(),
                );
                if (broadcast == true) ref.invalidate(announcementsProvider);
              },
              child: const Icon(Icons.campaign),
            )
          : null,
    );
  }
}
