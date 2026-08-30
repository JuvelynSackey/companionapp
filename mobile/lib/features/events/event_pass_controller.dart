import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/core_providers.dart';
import '../../data/models/campus_event.dart';
import '../../data/models/event_pass.dart';

class EventPassController extends Notifier<Map<int, EventPass>> {
  final _random = Random();

  @override
  Map<int, EventPass> build() => ref.watch(localPrefsProvider).eventPasses;

  EventPass? passFor(int eventId) => state[eventId];

  Future<EventPass> generate({
    required CampusEvent event,
    required String studentName,
    required String studentId,
  }) async {
    final pass = EventPass(
      passId: 'PASS-${DateTime.now().microsecondsSinceEpoch}-${_random.nextInt(99999)}',
      eventId: event.eventId,
      eventTitle: event.title,
      studentName: studentName,
      studentId: studentId,
      venue: event.location,
      eventDate: event.eventDate,
    );
    final updated = {...state, event.eventId: pass};
    await ref.read(localPrefsProvider).saveEventPasses(updated);
    state = updated;
    return pass;
  }

  Future<void> revoke(int eventId) async {
    final updated = {...state}..remove(eventId);
    await ref.read(localPrefsProvider).saveEventPasses(updated);
    state = updated;
  }
}

final eventPassControllerProvider = NotifierProvider<EventPassController, Map<int, EventPass>>(
  EventPassController.new,
);
