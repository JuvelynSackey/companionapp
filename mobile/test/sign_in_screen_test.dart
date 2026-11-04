import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/widgets/brand_logo.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/core/network/api_exception.dart';
import 'package:mobile/core/providers/core_providers.dart';
import 'package:mobile/core/storage/local_prefs.dart';
import 'package:mobile/core/storage/token_storage.dart';
import 'package:mobile/data/api/auth_api.dart';
import 'package:mobile/data/models/app_user.dart';
import 'package:mobile/data/repositories/auth_repository.dart';
import 'package:mobile/features/auth/sign_in_screen.dart';
import 'package:mobile/features/auth/sign_up_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/google_auth_fakes.dart';

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

  Object? loginError;
  AppUser? loginResult;
  final logins = <({String email, String password})>[];

  @override
  Future<AuthResult> login({required String email, required String password}) async {
    logins.add((email: email, password: password));
    if (loginError != null) throw loginError!;
    return AuthResult('jwt', loginResult ?? AppUser(userId: 1, fullName: 'A', email: email, role: 'student', permissions: const {}));
  }
}

Future<Widget> _app({_FakeAuthApi? api, bool showExpiredNotice = false}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await LocalPrefs.create();
  return ProviderScope(
    overrides: [
      localPrefsProvider.overrideWithValue(prefs),
      authRepositoryProvider.overrideWithValue(
        AuthRepository(api ?? _FakeAuthApi(), _TokenStorage(), googleAuth: FakeGoogleAuthService(available: false)),
      ),
    ],
    child: MaterialApp(home: SignInScreen(showExpiredNotice: showExpiredNotice)),
  );
}

Finder get _email => find.widgetWithText(TextFormField, 'Email');
Finder get _password => find.widgetWithText(TextFormField, 'Password');

/// The default 800x600 test surface is shorter than this screen's content,
/// which puts the lower buttons/links below the visible area and out of
/// tap()'s reach — see admin_dashboard_screen_test.dart for the same pattern.
void _tallScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('shows the Login headline and both fields', (tester) async {
    _tallScreen(tester);
    await tester.pumpWidget(await _app());
    await tester.pumpAndSettle();

    expect(find.text('Login'), findsNWidgets(2), reason: 'the headline and the submit button both say "Login"');
    expect(find.byType(BrandLogo), findsOneWidget);
    expect(_email, findsOneWidget);
    expect(_password, findsOneWidget);
  });

  testWidgets('the expired-session notice shows only when asked for', (tester) async {
    _tallScreen(tester);
    await tester.pumpWidget(await _app(showExpiredNotice: true));
    await tester.pumpAndSettle();
    expect(find.textContaining('session expired'), findsOneWidget);

    await tester.pumpWidget(await _app());
    await tester.pumpAndSettle();
    expect(find.textContaining('session expired'), findsNothing);
  });

  testWidgets('validates before submitting: a bad email and a short password both get an error, nothing is sent', (tester) async {
    _tallScreen(tester);
    final api = _FakeAuthApi();
    await tester.pumpWidget(await _app(api: api));
    await tester.pumpAndSettle();

    await tester.enterText(_email, 'not-an-email');
    await tester.enterText(_password, 'short');
    await tester.tap(find.widgetWithText(FilledButton, 'Login'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a valid email'), findsOneWidget);
    expect(find.text('Minimum 8 characters'), findsOneWidget);
    expect(api.logins, isEmpty);
  });

  testWidgets('a correct submit logs in with the trimmed email', (tester) async {
    _tallScreen(tester);
    final api = _FakeAuthApi();
    await tester.pumpWidget(await _app(api: api));
    await tester.pumpAndSettle();

    await tester.enterText(_email, '  student@ug.edu.gh  ');
    await tester.enterText(_password, 'password123');
    await tester.tap(find.widgetWithText(FilledButton, 'Login'));
    await tester.pumpAndSettle();

    expect(api.logins.single.email, 'student@ug.edu.gh');
    expect(api.logins.single.password, 'password123');
  });

  testWidgets('a rejected login shows the backend\'s message', (tester) async {
    _tallScreen(tester);
    final api = _FakeAuthApi()..loginError = ApiException('Incorrect email or password', statusCode: 401);
    await tester.pumpWidget(await _app(api: api));
    await tester.pumpAndSettle();

    await tester.enterText(_email, 'student@ug.edu.gh');
    await tester.enterText(_password, 'wrongpassword');
    await tester.tap(find.widgetWithText(FilledButton, 'Login'));
    await tester.pumpAndSettle();

    expect(find.text('Incorrect email or password'), findsOneWidget);
  });

  testWidgets('the password visibility toggle shows and hides the text', (tester) async {
    _tallScreen(tester);
    await tester.pumpWidget(await _app());
    await tester.pumpAndSettle();

    bool obscured() => tester
        .widget<EditableText>(find.descendant(of: _password, matching: find.byType(EditableText)))
        .obscureText;

    expect(obscured(), isTrue);
    expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);

    await tester.tap(find.byIcon(Icons.visibility_outlined));
    await tester.pump();

    expect(obscured(), isFalse);
    expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
  });

  testWidgets('offers no Forgot Password or Apple sign-in, since neither is built', (tester) async {
    _tallScreen(tester);
    await tester.pumpWidget(await _app());
    await tester.pumpAndSettle();

    expect(find.text('Forgot Password?'), findsNothing);
    expect(find.textContaining('Apple'), findsNothing);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Continue as Guest'), findsOneWidget);
  });

  testWidgets('"Need an account? Sign up" opens the sign-up screen', (tester) async {
    _tallScreen(tester);
    await tester.pumpWidget(await _app());
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('Need an account', findRichText: true));
    await tester.pumpAndSettle();

    expect(find.byType(SignUpScreen), findsOneWidget);
  });

  testWidgets('the Google row is present without a GoogleAuthService override', (tester) async {
    _tallScreen(tester);
    await tester.pumpWidget(await _app());
    await tester.pumpAndSettle();

    expect(find.text('Continue with Google'), findsOneWidget);
  });
}
