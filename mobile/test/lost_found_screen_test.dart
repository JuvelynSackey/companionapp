import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/core/network/api_exception.dart';
import 'package:mobile/core/providers/core_providers.dart';
import 'package:mobile/core/storage/token_storage.dart';
import 'package:mobile/data/api/lost_found_api.dart';
import 'package:mobile/data/models/app_user.dart';
import 'package:mobile/data/models/lost_found_item.dart';
import 'package:mobile/features/auth/session_controller.dart';
import 'package:mobile/features/lost_found/lost_found_screen.dart';

import 'support/admin_fakes.dart';

/// Records what the screen asks the server to do.
class _FakeApi extends LostFoundApi {
  _FakeApi(this.items) : super(ApiClient(TokenStorage()));
  List<LostFoundItem> items;
  final posts = <Map<String, Object?>>[];
  final returned = <int>[];
  final removed = <int>[];
  ApiException? refuse;

  @override
  Future<List<LostFoundItem>> fetch() async => items;

  @override
  Future<void> post({required LostFoundKind kind, required String title, String? description, String? location, String? contact}) async {
    posts.add({'kind': kind, 'title': title, 'description': description, 'location': location, 'contact': contact});
  }

  @override
  Future<void> markReturned(int itemId) async {
    if (refuse != null) throw refuse!;
    returned.add(itemId);
  }

  @override
  Future<void> remove(int itemId) async => removed.add(itemId);
}

LostFoundItem _item(int id, {bool mine = false, bool canManage = false, bool returned = false, LostFoundKind kind = LostFoundKind.lost}) =>
    LostFoundItem(
      itemId: id,
      kind: kind,
      title: 'Item $id',
      location: 'Balme Library',
      description: 'Blue with a sticker',
      isReturned: returned,
      createdAt: DateTime.utc(2026, 11, 4, 10),
      postedBy: 'Ama Owusu',
      contact: '024 000 0000',
      isMine: mine,
      canManage: canManage,
    );

Future<_FakeApi> _pump(WidgetTester tester, List<LostFoundItem> items) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final api = _FakeApi(items);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      lostFoundApiProvider.overrideWithValue(api),
      // Signed in, so posting needs no sign-in prompt.
      sessionControllerProvider.overrideWith(
        () => FakeSessionController(AppUser(userId: 7, fullName: 'Ama Owusu', email: 'ama@ug.edu.gh', role: 'student', permissions: const {})),
      ),
    ],
    child: const MaterialApp(home: LostFoundScreen()),
  ));
  // In the app the session is restored before any screen opens; here it is
  // loaded explicitly, so the sign-in check sees the signed-in user.
  final container = ProviderScope.containerOf(tester.element(find.byType(LostFoundScreen)));
  container.listen(sessionControllerProvider, (_, _) {});
  await tester.runAsync(() => container.read(sessionControllerProvider.future));
  await tester.pumpAndSettle();
  return api;
}

void main() {
  test('an item reads the server\'s JSON, including a guest\'s missing name and contact', () {
    final item = LostFoundItem.fromJson({
      'itemId': 4, 'kind': 'found', 'title': 'Calculator', 'description': null, 'location': null,
      'status': 'returned', 'createdAt': '2026-11-04T10:00:00.000Z', 'postedBy': null, 'contact': null,
      'isMine': false, 'canManage': false,
    });
    expect(item.kind, LostFoundKind.found);
    expect(item.isReturned, isTrue);
    expect(item.postedBy, isNull);
    expect(item.contact, isNull);
  });

  testWidgets('shows the shared board, with no sample items when nothing is posted', (tester) async {
    await _pump(tester, []);
    expect(find.textContaining('Nothing has been posted yet'), findsOneWidget);
  });

  testWidgets('shows each post with its place, details and how to reach the poster', (tester) async {
    await _pump(tester, [_item(1), _item(2, kind: LostFoundKind.found, returned: true)]);

    expect(find.text('Item 1'), findsOneWidget);
    expect(find.text('Item 2'), findsOneWidget);
    expect(find.text('Lost'), findsOneWidget);
    expect(find.text('Found'), findsOneWidget);
    expect(find.text('Returned'), findsOneWidget);
    expect(find.textContaining('Posted by Ama Owusu · Contact: 024 000 0000'), findsNWidgets(2));
  });

  testWidgets('only items the user may manage offer Mark returned and Remove', (tester) async {
    final api = await _pump(tester, [_item(1), _item(2, mine: true, canManage: true)]);

    expect(find.text('Mark returned'), findsOneWidget);
    expect(find.text('Remove'), findsOneWidget);

    await tester.tap(find.text('Mark returned'));
    await tester.pumpAndSettle();
    expect(api.returned, [2]);
    expect(find.text('Marked as returned.'), findsOneWidget);

    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();
    expect(api.removed, [2]);
  });

  testWidgets('a refused change shows the server\'s reason', (tester) async {
    final api = await _pump(tester, [_item(2, mine: true, canManage: true)]);
    api.refuse = ApiException('Only the person who posted this item can change it', statusCode: 403);

    await tester.tap(find.text('Mark returned'));
    await tester.pumpAndSettle();
    expect(find.text('Only the person who posted this item can change it'), findsOneWidget);
  });

  testWidgets('posting sends the item to the server and refreshes the board', (tester) async {
    final api = await _pump(tester, []);

    await tester.tap(find.text('Post an item'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('I found this'));
    await tester.enterText(find.widgetWithText(TextFormField, 'What is it?'), 'Black umbrella');
    await tester.enterText(find.widgetWithText(TextFormField, 'Where (optional)'), 'Great Hall');
    api.items = [_item(9, mine: true, canManage: true, kind: LostFoundKind.found)];
    await tester.tap(find.text('Post'));
    await tester.pumpAndSettle();

    expect(api.posts, [
      {'kind': LostFoundKind.found, 'title': 'Black umbrella', 'description': '', 'location': 'Great Hall', 'contact': ''},
    ]);
    expect(find.text('Item 9'), findsOneWidget, reason: 'the board was fetched again');
  });

  testWidgets('a title under three characters is not posted', (tester) async {
    final api = await _pump(tester, []);

    await tester.tap(find.text('Post an item'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'What is it?'), 'ab');
    await tester.tap(find.text('Post'));
    await tester.pumpAndSettle();

    expect(find.text('At least 3 characters'), findsOneWidget);
    expect(api.posts, isEmpty);
  });
}
