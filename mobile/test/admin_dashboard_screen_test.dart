import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/network/api_exception.dart';
import 'package:mobile/core/providers/core_providers.dart';
import 'package:mobile/data/models/app_user.dart';
import 'package:mobile/features/admin/admin_dashboard_screen.dart';
import 'package:mobile/features/auth/session_controller.dart';

import 'support/admin_fakes.dart';

Widget _app(FakeAdminApi api, AppUser? user) => ProviderScope(
      overrides: [
        adminApiProvider.overrideWithValue(api),
        sessionControllerProvider.overrideWith(() => FakeSessionController(user)),
      ],
      child: const MaterialApp(home: AdminDashboardScreen()),
    );

/// The form is taller than the default 800x600 test surface.
void _tallScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Finder _field(String label) => find.widgetWithText(TextFormField, label);
String _text(WidgetTester tester, String label) => tester.widget<TextFormField>(_field(label)).controller!.text;

Future<void> _fill(WidgetTester tester, {String name = 'Dr. Ama Mensah', String email = 'ama@ug.edu.gh', String password = 'longenough1'}) async {
  await tester.enterText(_field('Full name'), name);
  await tester.enterText(_field('Email'), email);
  await tester.enterText(_field('Password'), password);
}

Future<void> _submit(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
  await tester.pumpAndSettle();
}

void main() {
  group('access', () {
    for (final user in [studentUser, lecturerUser, null]) {
      testWidgets('${user?.role ?? 'signed-out user'} sees no form, only a notice', (tester) async {
        _tallScreen(tester);
        await tester.pumpWidget(_app(FakeAdminApi(), user));
        await tester.pumpAndSettle();

        expect(find.text('This area is for administrators only.'), findsOneWidget);
        expect(find.byType(TextFormField), findsNothing);
        expect(find.text('Create account'), findsNothing);
      });
    }

    testWidgets('an admin sees the form', (tester) async {
      _tallScreen(tester);
      await tester.pumpWidget(_app(FakeAdminApi(), adminUser));
      await tester.pumpAndSettle();

      expect(find.text('This area is for administrators only.'), findsNothing);
      expect(_field('Full name'), findsOneWidget);
      expect(_field('Email'), findsOneWidget);
      expect(_field('Password'), findsOneWidget);
      expect(find.text('Lecturer'), findsOneWidget);
      expect(find.text('Admin'), findsOneWidget);
    });
  });

  group('validation', () {
    testWidgets('an empty form shows every error and sends nothing', (tester) async {
      _tallScreen(tester);
      final api = FakeAdminApi();
      await tester.pumpWidget(_app(api, adminUser));
      await tester.pumpAndSettle();

      await _submit(tester);

      expect(find.text('Enter at least 2 characters'), findsOneWidget);
      expect(find.text('Enter a valid email address'), findsOneWidget);
      expect(find.text('Password must be at least 8 characters'), findsOneWidget);
      expect(api.provisioned, isEmpty);
    });

    testWidgets('a short password and a malformed email are rejected client-side', (tester) async {
      _tallScreen(tester);
      final api = FakeAdminApi();
      await tester.pumpWidget(_app(api, adminUser));
      await tester.pumpAndSettle();

      await _fill(tester, email: 'not-an-email', password: 'short');
      await _submit(tester);

      expect(find.text('Enter a valid email address'), findsOneWidget);
      expect(find.text('Password must be at least 8 characters'), findsOneWidget);
      expect(api.provisioned, isEmpty);
    });
  });

  group('provisioning', () {
    testWidgets('success sends trimmed values, confirms, and clears the form', (tester) async {
      _tallScreen(tester);
      final api = FakeAdminApi();
      await tester.pumpWidget(_app(api, adminUser));
      await tester.pumpAndSettle();

      await _fill(tester, name: '  Dr. Ama Mensah  ', email: ' ama@ug.edu.gh ');
      await _submit(tester);

      expect(api.provisioned.single, {
        'fullName': 'Dr. Ama Mensah',
        'email': 'ama@ug.edu.gh',
        'password': 'longenough1',
        'role': 'lecturer',
      });
      expect(find.text('Created lecturer account for Dr. Ama Mensah.'), findsOneWidget);
      expect(_text(tester, 'Full name'), isEmpty);
      expect(_text(tester, 'Email'), isEmpty);
      expect(_text(tester, 'Password'), isEmpty);
      expect(find.text('Enter at least 2 characters'), findsNothing, reason: 'no error flash after reset');
    });

    testWidgets('a duplicate email (409) shows the backend message and keeps what was typed', (tester) async {
      _tallScreen(tester);
      final api = FakeAdminApi()
        ..provisionError = ApiException('An account with that email already exists', statusCode: 409);
      await tester.pumpWidget(_app(api, adminUser));
      await tester.pumpAndSettle();

      await _fill(tester);
      await _submit(tester);

      expect(find.text('An account with that email already exists'), findsOneWidget, reason: 'SnackBar');
      expect(find.textContaining('Created'), findsNothing);
      expect(_text(tester, 'Email'), 'ama@ug.edu.gh');
      expect(_text(tester, 'Password'), 'longenough1');
    });

    testWidgets('server-side validation details are shown', (tester) async {
      _tallScreen(tester);
      final api = FakeAdminApi()
        ..provisionError = ApiException('Validation failed', statusCode: 400, details: ['Enter a valid email address']);
      await tester.pumpWidget(_app(api, adminUser));
      await tester.pumpAndSettle();

      await _fill(tester);
      await _submit(tester);

      expect(find.text('Validation failed: Enter a valid email address'), findsOneWidget);
    });

    testWidgets('after a failure the admin can fix the form and succeed', (tester) async {
      _tallScreen(tester);
      final api = FakeAdminApi()..provisionError = ApiException('nope', statusCode: 500);
      await tester.pumpWidget(_app(api, adminUser));
      await tester.pumpAndSettle();

      await _fill(tester);
      await _submit(tester);
      api.provisionError = null;
      await _submit(tester);

      expect(api.provisioned.length, 2);
      expect(find.text('Created lecturer account for Dr. Ama Mensah.'), findsOneWidget);
    });

    testWidgets('the button is disabled while the request is in flight', (tester) async {
      _tallScreen(tester);
      final api = FakeAdminApi();
      final gate = Completer<void>();
      api.onProvision = () => gate.future;
      await tester.pumpWidget(_app(api, adminUser));
      await tester.pumpAndSettle();

      await _fill(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
      await tester.pump();

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      gate.complete();
      await tester.pumpAndSettle();
      expect(api.provisioned.length, 1);
    });
  });

  group('creating an admin account', () {
    testWidgets('asks for confirmation, and cancelling sends nothing', (tester) async {
      _tallScreen(tester);
      final api = FakeAdminApi();
      await tester.pumpWidget(_app(api, adminUser));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Admin'));
      await tester.pumpAndSettle();
      await _fill(tester);
      await _submit(tester);

      expect(find.text('Create an admin account?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(api.provisioned, isEmpty);
      expect(_text(tester, 'Email'), 'ama@ug.edu.gh', reason: 'form untouched');
    });

    testWidgets('confirming creates the admin', (tester) async {
      _tallScreen(tester);
      final api = FakeAdminApi();
      await tester.pumpWidget(_app(api, adminUser));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Admin'));
      await tester.pumpAndSettle();
      await _fill(tester);
      await _submit(tester);
      await tester.tap(find.text('Create admin'));
      await tester.pumpAndSettle();

      expect(api.provisioned.single['role'], 'admin');
      expect(find.text('Created admin account for Dr. Ama Mensah.'), findsOneWidget);
    });

    testWidgets('a lecturer is created without a confirmation dialog', (tester) async {
      _tallScreen(tester);
      final api = FakeAdminApi();
      await tester.pumpWidget(_app(api, adminUser));
      await tester.pumpAndSettle();

      await _fill(tester);
      await _submit(tester);

      expect(find.text('Create an admin account?'), findsNothing);
      expect(api.provisioned.single['role'], 'lecturer');
    });

    testWidgets('the role goes back to lecturer after a successful create', (tester) async {
      _tallScreen(tester);
      final api = FakeAdminApi();
      await tester.pumpWidget(_app(api, adminUser));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Admin'));
      await tester.pumpAndSettle();
      await _fill(tester);
      await _submit(tester);
      await tester.tap(find.text('Create admin'));
      await tester.pumpAndSettle();

      final segmented = tester.widget<SegmentedButton<String>>(find.byType(SegmentedButton<String>));
      expect(segmented.selected, {'lecturer'});
    });
  });
}
