import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/network/api_exception.dart';
import 'package:mobile/core/providers/core_providers.dart';
import 'package:mobile/data/models/campus_event.dart';
import 'package:mobile/data/models/club.dart';
import 'package:mobile/features/clubs/clubs_screen.dart';

import 'support/club_fakes.dart';

CampusEvent _event(int id, String title, String? clubName) => CampusEvent(
      eventId: id,
      title: title,
      description: '',
      eventDate: DateTime.utc(2030, 5, 1, 14),
      location: 'Great Hall',
      clubName: clubName,
      attendeeCount: 7,
      isRegistered: false,
    );

Widget _app(FakeClubApi clubs, {FakeEventApi? events}) => ProviderScope(
      overrides: [
        clubApiProvider.overrideWithValue(clubs),
        eventApiProvider.overrideWithValue(events ?? FakeEventApi([])),
      ],
      child: const MaterialApp(home: ClubsScreen()),
    );

Finder _inCard(String clubName, Finder matching) =>
    find.descendant(of: find.widgetWithText(Card, clubName), matching: matching);

void main() {
  testWidgets('lists every club with its member count and a badge on joined ones', (tester) async {
    await tester.pumpWidget(_app(FakeClubApi([cs, debate, photo])));
    await tester.pumpAndSettle();

    expect(find.text('Computer Science Society'), findsOneWidget);
    expect(find.text('Debate Union'), findsOneWidget);
    expect(find.text('Photography Club'), findsOneWidget);
    expect(find.text('3 members'), findsOneWidget);
    expect(find.text('1 member'), findsOneWidget, reason: 'singular');
    expect(find.text('Member'), findsOneWidget, reason: 'badge only on the joined club');
    expect(_inCard('Debate Union', find.text('Leave')), findsOneWidget);
    expect(_inCard('Computer Science Society', find.text('Join')), findsOneWidget);
  });

  testWidgets('tapping Join flips the button to Leave and bumps the count', (tester) async {
    final api = FakeClubApi([cs, debate]);
    await tester.pumpWidget(_app(api));
    await tester.pumpAndSettle();

    await tester.tap(_inCard('Computer Science Society', find.text('Join')));
    await tester.pumpAndSettle();

    expect(api.joined, [1]);
    expect(_inCard('Computer Science Society', find.text('Leave')), findsOneWidget);
    expect(find.text('4 members'), findsOneWidget);
    expect(find.text('Member'), findsNWidgets(2));
  });

  testWidgets('a failed join reverts the club and tells the student why', (tester) async {
    final api = FakeClubApi([cs])
      ..onJoin = (_) async => throw ApiException('Club not found', statusCode: 404);
    await tester.pumpWidget(_app(api));
    await tester.pumpAndSettle();

    await tester.tap(_inCard('Computer Science Society', find.text('Join')));
    await tester.pumpAndSettle();

    expect(find.text('Club not found'), findsOneWidget, reason: 'SnackBar');
    expect(_inCard('Computer Science Society', find.text('Join')), findsOneWidget);
    expect(find.text('3 members'), findsOneWidget);
    expect(find.text('Member'), findsNothing);
  });

  testWidgets('search narrows the list, and shows a message when nothing matches', (tester) async {
    await tester.pumpWidget(_app(FakeClubApi([cs, debate, photo])));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'debate');
    await tester.pumpAndSettle();
    expect(find.text('Debate Union'), findsOneWidget);
    expect(find.text('Photography Club'), findsNothing);

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pumpAndSettle();
    expect(find.text('No clubs match your search.'), findsOneWidget);
  });

  testWidgets('My clubs shows only joined clubs', (tester) async {
    await tester.pumpWidget(_app(FakeClubApi([cs, debate, photo])));
    await tester.pumpAndSettle();

    await tester.tap(find.text('My clubs'));
    await tester.pumpAndSettle();

    expect(find.text('Debate Union'), findsOneWidget);
    expect(find.text('Computer Science Society'), findsNothing);
    expect(find.text('Photography Club'), findsNothing);
  });

  testWidgets('says so when there are no clubs at all', (tester) async {
    await tester.pumpWidget(_app(FakeClubApi([])));
    await tester.pumpAndSettle();

    expect(find.text('No clubs yet.'), findsOneWidget);
  });

  testWidgets('a load failure offers Retry, which reloads', (tester) async {
    final api = FakeClubApi([cs]);
    var failNext = true;
    final failing = _FailingOnceApi(api, () => failNext);
    await tester.pumpWidget(_app(failing));
    await tester.pumpAndSettle();

    expect(find.text('Retry'), findsOneWidget);

    failNext = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('Computer Science Society'), findsOneWidget);
  });

  group('club detail', () {
    testWidgets('opens from a card and shows only that club\'s upcoming events', (tester) async {
      final events = FakeEventApi([
        _event(1, 'Hackathon 2030', 'Computer Science Society'),
        _event(2, 'Debate Night', 'Debate Union'),
        _event(3, 'Convocation', null),
      ]);
      await tester.pumpWidget(_app(FakeClubApi([cs, debate]), events: events));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Computer Science Society'));
      await tester.pumpAndSettle();

      expect(find.text('Hackathon 2030'), findsOneWidget);
      expect(find.text('Debate Night'), findsNothing);
      expect(find.text('Convocation'), findsNothing);
      expect(find.text('Hackathons and study groups.'), findsOneWidget);
      expect(find.text('Upcoming events'), findsOneWidget);
    });

    testWidgets('says so when the club has no upcoming events', (tester) async {
      await tester.pumpWidget(_app(FakeClubApi([cs])));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Computer Science Society'));
      await tester.pumpAndSettle();

      expect(find.text('No upcoming events from this club.'), findsOneWidget);
    });

    testWidgets('joining here is reflected on the list behind it', (tester) async {
      final api = FakeClubApi([cs]);
      await tester.pumpWidget(_app(api));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Computer Science Society'));
      await tester.pumpAndSettle();
      expect(find.text("You're a member"), findsNothing);

      await tester.tap(find.widgetWithText(FilledButton, 'Join'));
      await tester.pumpAndSettle();
      expect(find.text("You're a member"), findsOneWidget);
      expect(find.text('4 members'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(_inCard('Computer Science Society', find.text('Leave')), findsOneWidget);
      expect(find.text('4 members'), findsOneWidget);
    });
  });
}

/// Fails fetch() while [shouldFail] returns true, then behaves like [inner].
class _FailingOnceApi extends FakeClubApi {
  _FailingOnceApi(FakeClubApi inner, this.shouldFail) : super(inner.clubs);
  final bool Function() shouldFail;

  @override
  Future<List<Club>> fetch() {
    if (shouldFail()) throw ApiException('Could not reach the server.');
    return super.fetch();
  }
}
