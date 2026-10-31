import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medi_hub/core/theme/app_theme.dart';
import 'package:medi_hub/data/repositories/auth_repository.dart';
import 'package:medi_hub/logic/auth/auth_bloc.dart';
import 'package:medi_hub/data/models/user_model.dart';
import 'package:medi_hub/presentation/screens/auth_screen.dart';

// Simple mock/stub for AuthRepository implementing interface directly
class FakeAuthRepository implements AuthRepository {
  @override
  Stream<User?> get authStateChanges => const Stream.empty();

  @override
  User? get currentFirebaseUser => null;

  @override
  Future<UserModel> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    return UserModel(
      uid: 'fake_uid',
      fullName: fullName,
      email: email,
      emailVerified: true,
      onboardingStatus: OnboardingStep.emailVerified,
    );
  }

  @override
  Future<UserModel?> login({
    required String email,
    required String password,
  }) async => null;

  @override
  Future<UserModel?> getCurrentUserModel() async => null;

  @override
  Future<UserModel?> getLocallyStoredUser() async => null;

  @override
  Future<void> saveLocally(UserModel user) async {}

  @override
  Future<bool> checkEmailVerified(UserModel currentUser) async => true;

  @override
  Future<void> resendVerificationEmail() async {}

  @override
  Future<void> correctEmailAndResend({
    required UserModel currentUser,
    required String newEmail,
  }) async {}

  @override
  Future<void> sendPasswordReset(String email) async {}

  @override
  Future<void> signOut() async {}
}

void main() {
  group('AuthScreen Widget Tests', () {
    late FakeAuthRepository fakeAuthRepository;
    late AuthBloc authBloc;

    setUp(() {
      fakeAuthRepository = FakeAuthRepository();
      authBloc = AuthBloc(authRepository: fakeAuthRepository);
    });

    tearDown(() {
      authBloc.close();
    });

    Widget createTestApp(WidgetTester tester, {AuthTab initialTab = AuthTab.login}) {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      return MaterialApp(
        theme: AppTheme.lightTheme,
        home: BlocProvider<AuthBloc>.value(
          value: authBloc,
          child: AuthScreen(
            initialTab: initialTab,
          ),
        ),
      );
    }

    testWidgets('AuthScreen renders tabs and starts on Login view by default', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp(tester, initialTab: AuthTab.login));
      await tester.pumpAndSettle();

      // Check tab buttons
      expect(find.text('Log In'), findsWidgets);
      expect(find.text('Register'), findsOneWidget);

      // Check Login form elements
      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Forgot Password?'), findsOneWidget);
      expect(find.text('Not registered yet? '), findsOneWidget);
    });

    testWidgets('AuthScreen starts on Register view when initialTab is register', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp(tester, initialTab: AuthTab.register));
      await tester.pumpAndSettle();

      // Check Register form elements
      expect(find.text('Create MediHub Account'), findsOneWidget);
      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Confirm Password'), findsOneWidget);
      expect(find.text('Register & Continue'), findsOneWidget);
      expect(find.text('Already have an account? '), findsOneWidget);
    });

    testWidgets('Tapping Register tab switches to register view', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp(tester, initialTab: AuthTab.login));
      await tester.pumpAndSettle();

      // Find the Register tab button and tap it
      await tester.tap(find.text('Register'));
      await tester.pumpAndSettle();

      expect(find.text('Create MediHub Account'), findsOneWidget);
      expect(find.text('Full Name'), findsOneWidget);
    });

    testWidgets('Tapping Create Account link on Login view switches to register tab', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp(tester, initialTab: AuthTab.login));
      await tester.pumpAndSettle();

      // Tap 'Create Account' link at bottom
      await tester.tap(find.text('Create Account'));
      await tester.pumpAndSettle();

      expect(find.text('Create MediHub Account'), findsOneWidget);
      expect(find.text('Full Name'), findsOneWidget);
    });
  });
}

