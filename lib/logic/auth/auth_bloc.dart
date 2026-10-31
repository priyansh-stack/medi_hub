import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/utils/validators.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;
  StreamSubscription<User?>? _authSubscription;

  AuthBloc({required this.authRepository})
      : super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthRegisterSubmitted>(_onAuthRegisterSubmitted);
    on<AuthLoginSubmitted>(_onAuthLoginSubmitted);
    on<AuthVerifyEmailCheckRequested>(_onAuthVerifyEmailCheckRequested);
    on<AuthResendVerificationRequested>(_onAuthResendVerificationRequested);
    on<AuthCorrectEmailRequested>(_onAuthCorrectEmailRequested);
    on<AuthPasswordResetRequested>(_onAuthPasswordResetRequested);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);
    on<AuthUserUpdated>((event, emit) async {
      if (event.user is UserModel) {
        final u = event.user as UserModel;
        await authRepository.saveLocally(u);
        emit(Authenticated(u));
      }
    });

    _authSubscription = authRepository.authStateChanges.listen((user) {
      if (user != null && state is! Authenticated) {
        add(AuthCheckRequested());
      } else if (user == null && state is Authenticated) {
        add(AuthCheckRequested());
      }
    });
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    // 1. Immediately restore locally stored user from SharedPreferences
    final cached = await authRepository.getLocallyStoredUser();
    if (cached != null) {
      emit(Authenticated(cached));
    } else {
      emit(const AuthLoading(message: 'Checking session...'));
    }

    try {
      final user = await authRepository.getCurrentUserModel();
      if (user != null) {
        emit(Authenticated(user));
      } else if (cached == null) {
        emit(Unauthenticated());
      }
    } catch (e) {
      if (cached == null) {
        emit(Unauthenticated());
      }
    }
  }

  Future<void> _onAuthRegisterSubmitted(
    AuthRegisterSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    final nameError = Validators.validateFullName(event.fullName);
    if (nameError != null) {
      emit(AuthFailure(nameError, field: 'fullName'));
      return;
    }

    final emailError = Validators.validateEmail(event.email);
    if (emailError != null) {
      emit(AuthFailure(emailError, field: 'email'));
      return;
    }

    final passwordError = Validators.validatePassword(event.password);
    if (passwordError != null) {
      emit(AuthFailure(passwordError, field: 'password'));
      return;
    }

    if (!event.termsAccepted) {
      emit(const AuthFailure('You must accept the Terms of Service and Privacy Policy to continue.', field: 'terms'));
      return;
    }

    emit(const AuthLoading(message: 'Creating your MediHub account...'));
    try {
      final normalizedEmail = Validators.normalizeEmail(event.email);
      final user = await authRepository.register(
        fullName: event.fullName.trim(),
        email: normalizedEmail,
        password: event.password,
      );
      emit(Authenticated(user));
    } on FirebaseAuthException catch (e) {
      String message;
      String? field;
      switch (e.code) {
        case 'email-already-in-use':
          message = 'An account with this email already exists. Please login instead.';
          field = 'email';
          break;
        case 'invalid-email':
          message = 'The email address is invalid.';
          field = 'email';
          break;
        case 'weak-password':
          message = 'The password is too weak. Please choose a stronger password.';
          field = 'password';
          break;
        default:
          message = e.message ?? 'Registration failed. Please try again.';
      }
      emit(AuthFailure(message, field: field));
    } catch (e) {
      emit(AuthFailure('Registration failed: ${e.toString()}'));
    }
  }

  Future<void> _onAuthLoginSubmitted(
    AuthLoginSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    final emailError = Validators.validateEmail(event.email);
    if (emailError != null) {
      emit(AuthFailure(emailError, field: 'email'));
      return;
    }

    if (event.password.isEmpty) {
      emit(const AuthFailure('Password is required', field: 'password'));
      return;
    }

    emit(const AuthLoading(message: 'Logging in to MediHub...'));
    try {
      final normalizedEmail = Validators.normalizeEmail(event.email);
      final user = await authRepository.login(
        email: normalizedEmail,
        password: event.password,
      );
      if (user != null) {
        emit(Authenticated(user));
      } else {
        emit(const AuthFailure('Could not find user profile. Please try again.'));
      }
    } on FirebaseAuthException catch (e) {
      String message;
      String? field;
      switch (e.code) {
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          message = 'Invalid email or password. Please check your credentials.';
          break;
        case 'user-disabled':
          message = 'This MediHub account has been disabled. Please contact support.';
          break;
        case 'too-many-requests':
          message = 'Too many failed login attempts. Please wait a moment and try again.';
          break;
        default:
          message = e.message ?? 'Login failed. Please try again.';
      }
      emit(AuthFailure(message, field: field));
    } catch (e) {
      emit(AuthFailure('Login failed: ${e.toString()}'));
    }
  }

  Future<void> _onAuthVerifyEmailCheckRequested(
    AuthVerifyEmailCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    final currentState = state;
    if (currentState is! Authenticated) return;

    emit(const AuthLoading(message: 'Checking verification status...'));
    try {
      final isVerified = await authRepository.checkEmailVerified(currentState.user);
      if (isVerified) {
        final updatedUser = currentState.user.copyWith(
          emailVerified: true,
          onboardingStatus: currentState.user.onboardingStatus == OnboardingStep.accountCreated
              ? OnboardingStep.emailVerified
              : currentState.user.onboardingStatus,
        );
        emit(AuthActionSuccess('Email verified successfully!', user: updatedUser));
        emit(Authenticated(updatedUser));
      } else {
        emit(const AuthFailure('Email is not verified yet. Please check your inbox and click the verification link.'));
        emit(Authenticated(currentState.user));
      }
    } catch (e) {
      emit(AuthFailure('Failed to check verification status: ${e.toString()}'));
      emit(Authenticated(currentState.user));
    }
  }

  Future<void> _onAuthResendVerificationRequested(
    AuthResendVerificationRequested event,
    Emitter<AuthState> emit,
  ) async {
    final currentState = state;
    if (currentState is! Authenticated) return;

    try {
      await authRepository.resendVerificationEmail();
      emit(const AuthActionSuccess('Verification email resent! Please check your inbox and spam folder.'));
      emit(Authenticated(currentState.user));
    } catch (e) {
      emit(AuthFailure('Failed to resend verification email: ${e.toString()}'));
      emit(Authenticated(currentState.user));
    }
  }

  Future<void> _onAuthCorrectEmailRequested(
    AuthCorrectEmailRequested event,
    Emitter<AuthState> emit,
  ) async {
    final currentState = state;
    if (currentState is! Authenticated) return;

    final emailError = Validators.validateEmail(event.newEmail);
    if (emailError != null) {
      emit(AuthFailure(emailError, field: 'email'));
      emit(Authenticated(currentState.user));
      return;
    }

    emit(const AuthLoading(message: 'Updating email address...'));
    try {
      final normalizedEmail = Validators.normalizeEmail(event.newEmail);
      await authRepository.correctEmailAndResend(
        currentUser: currentState.user,
        newEmail: normalizedEmail,
      );
      final updatedUser = currentState.user.copyWith(
        email: normalizedEmail,
        emailVerified: false,
        onboardingStatus: OnboardingStep.accountCreated,
      );
      emit(const AuthActionSuccess('Email updated! Verification link sent to your new address.'));
      emit(Authenticated(updatedUser));
    } catch (e) {
      emit(AuthFailure('Failed to update email: ${e.toString()}'));
      emit(Authenticated(currentState.user));
    }
  }

  Future<void> _onAuthPasswordResetRequested(
    AuthPasswordResetRequested event,
    Emitter<AuthState> emit,
  ) async {
    final emailError = Validators.validateEmail(event.email);
    if (emailError != null) {
      emit(AuthFailure(emailError, field: 'email'));
      return;
    }

    emit(const AuthLoading(message: 'Sending password reset email...'));
    try {
      await authRepository.sendPasswordReset(Validators.normalizeEmail(event.email));
      emit(const AuthActionSuccess('Password reset link has been sent to your email.'));
      emit(Unauthenticated());
    } catch (e) {
      emit(AuthFailure('Failed to send password reset: ${e.toString()}'));
    }
  }

  Future<void> _onAuthLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(message: 'Logging out...'));
    await authRepository.signOut();
    emit(Unauthenticated());
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}
