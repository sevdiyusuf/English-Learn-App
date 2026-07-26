import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yunoo/features/auth/logic/auth_controller.dart';
import 'package:yunoo/features/auth/models/app_user.dart';
import 'package:yunoo/features/auth/ui/email_auth_dialog.dart';
import 'package:yunoo/l10n/app_localizations.dart';

class MockAuthController extends StateNotifier<AsyncValue<AppUser?>>
    implements AuthController {
  MockAuthController() : super(const AsyncValue.data(null));

  @override
  Future<void> linkGoogleAccount() async {}

  @override
  Future<void> linkAppleAccount() async {}

  @override
  Future<void> reauthenticateWithGoogle() async {}

  @override
  Future<void> reauthenticateWithApple() async {}

  @override
  Future<void> reauthenticateWithPassword(String password) async {}

  int signInCallCount = 0;
  Completer<void>? signInCompleter;

  @override
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    signInCallCount++;
    if (signInCompleter != null) {
      await signInCompleter!.future;
    }
  }

  @override
  Future<void> continueAsGuest() async {}

  @override
  Future<void> deleteAccountAndData({String? password}) async {}

  @override
  Future<AppUser> ensureAnonymousGuestSignedIn() async =>
      AppUser(uid: 'guest', isAnonymous: true);

  @override
  Future<AppUser?> getCurrentUser() async => null;

  @override
  bool get isGuest => true;

  @override
  bool get isLoggedIn => false;

  @override
  Future<void> registerWithEmail({
    required String email,
    required String password,
    String? name,
  }) async {}

  @override
  Future<void> resetPassword(String email) async {}

  @override
  Future<void> signInWithApple() async {}

  @override
  Future<void> signInWithGoogle() async {}

  @override
  Future<void> signOut() async {}

  @override
  Future<void> updateDisplayName(String name) async {}
}

void main() {
  testWidgets('EmailAuthDialog prevents double submit', (tester) async {
    final mockController = MockAuthController();
    mockController.signInCompleter = Completer<void>();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith((ref) => mockController),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: EmailAuthDialog()),
        ),
      ),
    );

    // Enter valid email and password
    await tester.enterText(find.byType(TextFormField).at(0), 'test@test.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');
    await tester.pump();

    // Find the submit button
    final submitButton = find.byType(FilledButton);
    expect(submitButton, findsOneWidget);

    // Tap it once
    await tester.tap(submitButton);
    await tester.pump();

    // It should now be disabled (loading state)
    // Tap it again
    await tester.tap(submitButton);
    await tester.pump();

    // Sign in should only be called once
    expect(mockController.signInCallCount, equals(1));

    // Complete the future
    mockController.signInCompleter!.complete();
    await tester.pumpAndSettle();
  });
}
