import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/network/api_exception.dart';
import 'package:mobile/core/providers/core_providers.dart';
import 'package:mobile/data/models/campus_event.dart';
import 'package:mobile/data/models/club.dart';
import 'package:mobile/features/clubs/clubs_providers.dart';
import 'package:mobile/features/events/events_providers.dart';

import 'support/club_fakes.dart';

Future<ProviderContainer> makeContainer(FakeClubApi api, {FakeEventApi? events}) async {
  final container = ProviderContainer(overrides: [
    clubApiProvider.overrideWithValue(api),
    if (events != null) eventApiProvider.overrideWithValue(events),
  ]);
  addTearDown(container.dispose);
  // autoDispose providers need a listener to survive between reads.
  container.listen(clubsProvider, (_, _) {});
  await container.read(clubsProvider.future);
  return container;
}

Club clubIn(ProviderContainer c, int id) =>
    c.read(clubsProvider).requireValue.firstWhere((club) => club.clubId == id);

void main() {
  group('ClubsController.toggleMembership', () {
    test('joining updates the UI immediately, before the server answers', () async {
      final api = FakeClubApi([cs, debate]);
      final gate = Completer<void>();
      api.onJoin = (_) => gate.future;
      final container = await makeContainer(api);

      final pending = container.read(clubsProvider.notifier).toggleMembership(1);

      expect(clubIn(container, 1).isMember, isTrue);
      expect(clubIn(container, 1).memberCount, 4);
      expect(container.read(clubMembershipPendingProvider), {1});

      gate.complete();
      await pending;

      expect(clubIn(container, 1).isMember, isTrue);
      expect(container.read(clubMembershipPendingProvider), isEmpty);
      expect(api.joined, [1]);
    });

    test('leaving calls leave and removes the member', () async {
      final api = FakeClubApi([cs, debate]);
      final container = await makeContainer(api);

      await container.read(clubsProvider.notifier).toggleMembership(2);

      expect(api.left, [2]);
      expect(api.joined, isEmpty);
      expect(clubIn(container, 2).isMember, isFalse);
      expect(clubIn(container, 2).memberCount, 4);
    });

    test('a failed join rolls the club back and rethrows the error', () async {
      final api = FakeClubApi([cs, debate]);
      api.onJoin = (_) async => throw ApiException('Club not found', statusCode: 404);
      final container = await makeContainer(api);

      await expectLater(
        container.read(clubsProvider.notifier).toggleMembership(1),
        throwsA(isA<ApiException>()),
      );

      expect(clubIn(container, 1).isMember, isFalse);
      expect(clubIn(container, 1).memberCount, 3);
      expect(container.read(clubMembershipPendingProvider), isEmpty);
    });

    test('an unexpected (non-API) error also rolls back', () async {
      final api = FakeClubApi([cs]);
      api.onJoin = (_) async => throw StateError('boom');
      final container = await makeContainer(api);

      await expectLater(
        container.read(clubsProvider.notifier).toggleMembership(1),
        throwsA(isA<StateError>()),
      );

      expect(clubIn(container, 1).isMember, isFalse);
    });

    test('a failure on one club does not undo a successful toggle on another', () async {
      final api = FakeClubApi([cs, debate, photo]);
      final failingGate = Completer<void>();
      api.onJoin = (id) => id == 1 ? failingGate.future : Future.value();
      final container = await makeContainer(api);
      final controller = container.read(clubsProvider.notifier);

      final first = controller.toggleMembership(1); // stays in flight
      await controller.toggleMembership(3); // succeeds meanwhile
      failingGate.completeError(ApiException('nope', statusCode: 500));
      await expectLater(first, throwsA(isA<ApiException>()));

      expect(clubIn(container, 1).isMember, isFalse, reason: 'failed toggle rolled back');
      expect(clubIn(container, 3).isMember, isTrue, reason: 'unrelated success kept');
    });

    test('a second tap while the first is in flight is ignored', () async {
      final api = FakeClubApi([cs]);
      final gate = Completer<void>();
      api.onJoin = (_) => gate.future;
      final container = await makeContainer(api);
      final controller = container.read(clubsProvider.notifier);

      final first = controller.toggleMembership(1);
      await controller.toggleMembership(1);
      gate.complete();
      await first;

      expect(api.joined, [1], reason: 'only one request');
      expect(api.left, isEmpty);
      expect(clubIn(container, 1).isMember, isTrue);
      expect(clubIn(container, 1).memberCount, 4);
    });

    test('leaving a club the server says we are not in is not an error; the list is refetched', () async {
      final api = FakeClubApi([cs, debate]);
      api.onLeave = (_) async {
        api.clubs = [cs, debate.copyWith(isMember: false, memberCount: 4)];
        throw ApiException('You are not a member of that club', statusCode: 404);
      };
      final container = await makeContainer(api);

      await container.read(clubsProvider.notifier).toggleMembership(2);
      await container.read(clubsProvider.future);

      expect(api.fetchCount, 2);
      expect(clubIn(container, 2).isMember, isFalse);
      expect(clubIn(container, 2).memberCount, 4);
      expect(container.read(clubMembershipPendingProvider), isEmpty);
    });

    test('an unknown club id does nothing', () async {
      final api = FakeClubApi([cs]);
      final container = await makeContainer(api);

      await container.read(clubsProvider.notifier).toggleMembership(999);

      expect(api.joined, isEmpty);
      expect(api.left, isEmpty);
    });

    test('still completes if the listener goes away mid-request', () async {
      final api = FakeClubApi([cs]);
      final gate = Completer<void>();
      api.onJoin = (_) => gate.future;
      final container = ProviderContainer(overrides: [clubApiProvider.overrideWithValue(api)]);
      addTearDown(container.dispose);
      final sub = container.listen(clubsProvider, (_, _) {});
      await container.read(clubsProvider.future);

      final pending = container.read(clubsProvider.notifier).toggleMembership(1);
      sub.close(); // screen popped while the request is in flight
      await Future<void>.delayed(Duration.zero);
      gate.complete();

      await expectLater(pending, completes);
    });
  });

  group('filteredClubsProvider', () {
    test('returns everything with no query and the All filter', () async {
      final container = await makeContainer(FakeClubApi([cs, debate, photo]));
      container.listen(filteredClubsProvider, (_, _) {});

      expect(container.read(filteredClubsProvider).requireValue.length, 3);
    });

    test('search matches name or description, ignoring case and outer spaces', () async {
      final container = await makeContainer(FakeClubApi([cs, debate, photo]));
      container.listen(filteredClubsProvider, (_, _) {});

      container.read(clubSearchQueryProvider.notifier).state = '  DEBATE ';
      expect(container.read(filteredClubsProvider).requireValue.map((c) => c.clubId), [2]);

      container.read(clubSearchQueryProvider.notifier).state = 'hackathons';
      expect(container.read(filteredClubsProvider).requireValue.map((c) => c.clubId), [1]);

      container.read(clubSearchQueryProvider.notifier).state = 'zzz';
      expect(container.read(filteredClubsProvider).requireValue, isEmpty);
    });

    test('My clubs shows only joined clubs and follows a join', () async {
      final container = await makeContainer(FakeClubApi([cs, debate, photo]));
      container.listen(filteredClubsProvider, (_, _) {});
      container.read(clubFilterProvider.notifier).state = ClubFilter.mine;

      expect(container.read(filteredClubsProvider).requireValue.map((c) => c.clubId), [2]);

      await container.read(clubsProvider.notifier).toggleMembership(3);
      expect(container.read(filteredClubsProvider).requireValue.map((c) => c.clubId), [2, 3]);
    });

    test('search and My clubs combine', () async {
      final container = await makeContainer(FakeClubApi([cs, debate, photo]));
      container.listen(filteredClubsProvider, (_, _) {});
      container.read(clubFilterProvider.notifier).state = ClubFilter.mine;
      container.read(clubSearchQueryProvider.notifier).state = 'photo';

      expect(container.read(filteredClubsProvider).requireValue, isEmpty);
    });
  });

  group('clubByIdProvider and clubEventsProvider', () {
    CampusEvent event(int id, String title, String? clubName) => CampusEvent(
          eventId: id,
          title: title,
          description: '',
          eventDate: DateTime.utc(2030, 1, 1),
          location: null,
          clubName: clubName,
          attendeeCount: 0,
          isRegistered: false,
        );

    test('clubById finds a club and returns null for an unknown id', () async {
      final container = await makeContainer(FakeClubApi([cs, debate]));
      container.listen(clubByIdProvider(2), (_, _) {});
      container.listen(clubByIdProvider(42), (_, _) {});

      expect(container.read(clubByIdProvider(2))?.name, 'Debate Union');
      expect(container.read(clubByIdProvider(42)), isNull);
    });

    test('clubEvents keeps only that club\'s events', () async {
      final container = await makeContainer(
        FakeClubApi([cs, debate]),
        events: FakeEventApi([
          event(1, 'Hackathon', 'Computer Science Society'),
          event(2, 'Debate Night', 'Debate Union'),
          event(3, 'Convocation', null),
        ]),
      );
      final provider = clubEventsProvider('Computer Science Society');
      container.listen(provider, (_, _) {});
      await container.read(eventsProvider.future);

      final titles = container.read(provider).requireValue.map((e) => e.title).toList();
      expect(titles, ['Hackathon']);
    });
  });
}
