import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/core_providers.dart';
import '../../data/models/student_hub_fixtures.dart';
import '../../data/models/student_hub_models.dart';
import '../onboarding/institution_controller.dart';

final shuttleRoutesProvider = Provider<List<ShuttleRoute>>((ref) {
  final institution = ref.watch(institutionControllerProvider);
  return StudentHubFixtures.shuttlesFor(institution.id);
});

final campusDuesProvider = Provider<List<CampusDue>>((ref) {
  final institution = ref.watch(institutionControllerProvider);
  return StudentHubFixtures.duesFor(institution.id);
});

/// Simulated MoMo receipts, keyed by due id — paying a due writes a receipt
/// here; a due with no receipt is treated as unpaid. See MoMoReceipt's doc
/// comment for why this never touches a real payment gateway.
class MomoReceiptsController extends Notifier<Map<String, MoMoReceipt>> {
  final _random = Random();

  @override
  Map<String, MoMoReceipt> build() => ref.watch(localPrefsProvider).momoReceipts;

  MoMoReceipt? receiptFor(String dueId) => state[dueId];

  Future<MoMoReceipt> pay({
    required CampusDue due,
    required String payerName,
    required String studentId,
    required String momoNumber,
    required MoMoProvider provider,
  }) async {
    final receipt = MoMoReceipt(
      transactionRef: 'MM-${DateTime.now().millisecondsSinceEpoch}-${_random.nextInt(9999)}',
      dueId: due.id,
      itemTitle: due.title,
      amountGhs: due.amountGhs,
      payerName: payerName,
      studentId: studentId,
      momoNumber: momoNumber,
      provider: provider,
      timestamp: DateTime.now(),
    );
    final updated = {...state, due.id: receipt};
    await ref.read(localPrefsProvider).saveMomoReceipts(updated);
    state = updated;
    return receipt;
  }
}

final momoReceiptsControllerProvider =
    NotifierProvider<MomoReceiptsController, Map<String, MoMoReceipt>>(MomoReceiptsController.new);

/// Seed fixtures plus whatever the student has reported on this device,
/// newest first — never a shared/synced feed.
class LostFoundController extends Notifier<List<LostFoundItem>> {
  @override
  List<LostFoundItem> build() {
    final reported = ref.watch(localPrefsProvider).reportedLostFoundItems;
    return [...reported.reversed, ...StudentHubFixtures.lostFoundSeed()];
  }

  Future<void> report(LostFoundItem item) async {
    final current = ref.read(localPrefsProvider).reportedLostFoundItems;
    final updated = [...current, item];
    await ref.read(localPrefsProvider).saveReportedLostFoundItems(updated);
    state = [...updated.reversed, ...StudentHubFixtures.lostFoundSeed()];
  }
}

final lostFoundControllerProvider =
    NotifierProvider<LostFoundController, List<LostFoundItem>>(LostFoundController.new);
