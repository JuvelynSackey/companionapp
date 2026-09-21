import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/campus_companion_theme.dart';
import '../../data/models/student_hub_models.dart';
import '../../widgets/campus_card_tile.dart';
import 'momo_payment_dialog.dart';
import 'report_lost_found_dialog.dart';
import 'student_hub_providers.dart';

/// Student Hub: shuttles/trotro, MoMo dues, and lost & found — all
/// local-only fixture/simulated content, no backend tables exist for any of
/// this (see docs/phase-2-plan.md). Campus Events/Clubs and Official
/// Portals are backed by real data already and live on their own screens.
class StudentHubScreen extends StatelessWidget {
  const StudentHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Student Hub'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.directions_bus_outlined), text: 'Shuttles'),
              Tab(icon: Icon(Icons.payments_outlined), text: 'MoMo Dues'),
              Tab(icon: Icon(Icons.search_outlined), text: 'Lost & Found'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [_ShuttlesTab(), _DuesTab(), _LostFoundTab()],
        ),
      ),
    );
  }
}

Future<void> _call(BuildContext context, String phone) async {
  final uri = Uri(scheme: 'tel', path: phone.replaceAll(' ', ''));
  if (!await launchUrl(uri)) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not call $phone')));
    }
  }
}

class _ShuttlesTab extends ConsumerWidget {
  const _ShuttlesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routes = ref.watch(shuttleRoutesProvider);
    final campus = Theme.of(context).campusTheme;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: routes.length,
      itemBuilder: (context, index) {
        final route = routes[index];
        final occupancyColor = route.occupancyRatio > 0.8
            ? Theme.of(context).colorScheme.error
            : route.occupancyRatio > 0.5
                ? Colors.orange.shade700
                : Colors.green.shade600;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: campus.cardDecoration(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: campus.accentGlow.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
                    child: Text(route.routeCode, style: TextStyle(color: campus.accentGlow, fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(route.status, style: Theme.of(context).textTheme.bodySmall)),
                  Text('GH₵ ${route.fareGhs.toStringAsFixed(2)}', style: Theme.of(context).textTheme.titleSmall),
                ],
              ),
              const SizedBox(height: 8),
              Text(route.routeName, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text('${route.fromStop} → ${route.toStop}', style: TextStyle(color: campus.textMuted, fontSize: 12)),
              if (route.viaStops.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text('via ${route.viaStops.join(', ')}', style: TextStyle(color: campus.textMuted, fontSize: 11)),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.timer_outlined, size: 16, color: campus.accentGlow),
                  const SizedBox(width: 4),
                  Text('Next in ${route.nextArrivalMinutes} min', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Icon(Icons.event_seat_outlined, size: 16, color: occupancyColor),
                  const SizedBox(width: 4),
                  Text('${route.seatsAvailable}/${route.totalSeats} seats', style: TextStyle(color: occupancyColor, fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
              const Divider(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${route.busNumberPlate} · ${route.driverName}',
                      style: TextStyle(color: campus.textMuted, fontSize: 12),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _call(context, route.driverPhone),
                    icon: const Icon(Icons.call_outlined, size: 16),
                    label: const Text('Call driver'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DuesTab extends ConsumerWidget {
  const _DuesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dues = ref.watch(campusDuesProvider);
    final receipts = ref.watch(momoReceiptsControllerProvider);
    final campus = Theme.of(context).campusTheme;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: dues.length,
      itemBuilder: (context, index) {
        final due = dues[index];
        final receipt = receipts[due.id];
        final isPaid = receipt != null;

        return CampusCardTile(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: campus.cardDecoration(),
          radius: campus.cardRadius,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: campus.accentGlow.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
                    child: Text(due.category.label, style: TextStyle(color: campus.accentGlow, fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
                  const Spacer(),
                  if (isPaid)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
                      child: Text('PAID', style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold, fontSize: 11)),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(due.title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(due.description, style: TextStyle(color: campus.textMuted)),
              const SizedBox(height: 8),
              Text('Due by ${due.dueDate}', style: TextStyle(color: campus.textMuted, fontSize: 12)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('GH₵ ${due.amountGhs.toStringAsFixed(2)}', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  FilledButton.icon(
                    onPressed: isPaid
                        ? null
                        : () => showDialog<void>(context: context, builder: (_) => MomoPaymentDialog(due: due)),
                    icon: Icon(isPaid ? Icons.check : Icons.payments_outlined, size: 18),
                    label: Text(isPaid ? 'Receipt saved' : 'Pay with MoMo'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LostFoundTab extends ConsumerWidget {
  const _LostFoundTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(lostFoundControllerProvider);
    final campus = Theme.of(context).campusTheme;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showDialog<void>(context: context, builder: (_) => const ReportLostFoundDialog()),
        icon: const Icon(Icons.add),
        label: const Text('Report Item'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final isLost = item.status == LostFoundStatus.lost;
          final statusColor = isLost ? Colors.red.shade700 : Colors.green.shade700;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: campus.cardDecoration(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
                      child: Text(isLost ? 'LOST' : 'FOUND', style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(item.category.label, style: TextStyle(color: campus.textMuted, fontSize: 12))),
                    Text(item.dateReported, style: TextStyle(color: campus.textMuted, fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(item.title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(item.description, style: TextStyle(color: campus.textMuted)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.place_outlined, size: 14, color: campus.textMuted),
                    const SizedBox(width: 4),
                    Expanded(child: Text(item.campusLocation, style: TextStyle(color: campus.textMuted, fontSize: 12))),
                  ],
                ),
                if (item.claimInstructions != null) ...[
                  const SizedBox(height: 4),
                  Text(item.claimInstructions!, style: TextStyle(color: campus.textMuted, fontSize: 12, fontStyle: FontStyle.italic)),
                ],
                if (item.rewardGhs != null) ...[
                  const SizedBox(height: 8),
                  Text('Reward: GH₵ ${item.rewardGhs!.toStringAsFixed(2)}', style: TextStyle(color: Colors.orange.shade800, fontWeight: FontWeight.bold)),
                ],
                const Divider(height: 20),
                Row(
                  children: [
                    Expanded(child: Text('Reported by ${item.reporterName}', style: TextStyle(color: campus.textMuted, fontSize: 12))),
                    TextButton.icon(
                      onPressed: () => _call(context, item.contactPhone),
                      icon: const Icon(Icons.call_outlined, size: 16),
                      label: const Text('Contact'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
