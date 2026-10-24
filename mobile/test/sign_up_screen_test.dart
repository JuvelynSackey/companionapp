import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/core/network/api_exception.dart';
import 'package:mobile/core/providers/core_providers.dart';
import 'package:mobile/core/storage/local_prefs.dart';
import 'package:mobile/core/storage/token_storage.dart';
import 'package:mobile/data/api/auth_api.dart';
import 'package:mobile/data/models/app_user.dart';
import 'package:mobile/data/repositories/auth_repository.dart';
import 'package:mobile/features/auth/sign_up_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _TokenStorage extends TokenStorage {
  String? _token;
  @override
  Future<String?> readToken() async => _token;
  @override
  Future<void> saveToken(String token) async => _token = token;
  @override
  Future<void> clearToken() async => _token = null;
}

class _FakeAuthApi extends AuthApi {
  _FakeAuthApi() : super(ApiClient(TokenStorage()));

  Object? registerError;
  final registrations = <({String fullName, String email, String password})>[];

  @override
  Future<AuthResult> register({required String fullName, required String email, required String password}) async {
    registrations.add((fullName: fullName, email: email, password: password));
    if (registerError != null) throw registerError!;
    return AuthResult('jwt', AppUser(userId: 1, fullName: fullName, email: email, role: 'student', permissions: const {}));
  }
}

Future<Widget> _app(_FakeAuthApi api) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await LocalPrefs.create();
  return ProviderScope(
    overrides: [
      localPrefsProvider.overrideWithValue(prefs),
      authRepositoryProvider.overrideWithValue(AuthRepository(api, _TokenStorage())),
    ],
    child: MaterialApp(
      home: Navigator(
        onGenerateRoute: (_) => MaterialPageRoute(builder: (_) => const SignUpScreen()),
      ),
    ),
  );
}

void main() {
  testWidgets('validates all three fields before submitting', (tester) async {
    final api = _FakeAuthApi();
    await tester.pumpWidget(await _app(api));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Create Account'));
    await tester.pumpAndSettle();

    expect(find.text('Enter your full name'), findsOneWidget);
    expect(find.text('Enter a valid email'), findsOneWidget);
    expect(find.text('Minimum 8 characters'), findsOneWidget);
    expect(api.registrations, isEmpty);
  });

  testWidgets('a correct submit registers with the trimmed name and email, then pops', (tester) async {
    final api = _FakeAuthApi();
    await tester.pumpWidget(await _app(api));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Full name'), '  Ama Owusu  ');
    await tester.enterText(find.widgetWithText(TextFormField, 'Email'), '  ama@ug.edu.gh  ');
    await tester.enterText(find.widgetWithText(TextFormField, 'Password'), 'password123');
    await tester.tap(find.widgetWithText(FilledButton, 'Create Account'));
    await tester.pumpAndSettle();

    expect(api.registrations.single.fullName, 'Ama Owusu');
    expect(api.registrations.single.email, 'ama@ug.edu.gh');
    expect(find.byType(SignUpScreen), findsNothing, reason: 'popped back on success');
  });

  testWidgets('a duplicate-email rejection shows the message and stays on the screen', (tester) async {
    final api = _FakeAuthApi()..registerError = ApiException('An account with that email already exists', statusCode: 409);
    await tester.pumpWidget(await _app(api));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Full name'), 'Ama Owusu');
    await tester.enterText(find.widgetWithText(TextFormField, 'Email'), 'ama@ug.edu.gh');
    await tester.enterText(find.widgetWithText(TextFormField, 'Password'), 'password123');
    await tester.tap(find.widgetWithText(FilledButton, 'Create Account'));
    await tester.pumpAndSettle();

    expect(find.text('An account with that email already exists'), findsOneWidget);
    expect(find.byType(SignUpScreen), findsOneWidget);
  });

  testWidgets('the password visibility toggle works', (tester) async {
    await tester.pumpWidget(await _app(_FakeAuthApi()));
    await tester.pumpAndSettle();

    final field = find.widgetWithText(TextFormField, 'Password');
    bool obscured() =>
        tester.widget<EditableText>(find.descendant(of: field, matching: find.byType(EditableText))).obscureText;

    expect(obscured(), isTrue);

    await tester.tap(find.byIcon(Icons.visibility_outlined));
    await tester.pump();

    expect(obscured(), isFalse);
  });
}
