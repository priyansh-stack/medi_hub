import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {}

class AuthRegisterSubmitted extends AuthEvent {
  final String fullName;
  final String email;
  final String password;
  final bool termsAccepted;

  const AuthRegisterSubmitted({
    required this.fullName,
    required this.email,
    required this.password,
    required this.termsAccepted,
  });

  @override
  List<Object?> get props => [fullName, email, password, termsAccepted];
}

class AuthLoginSubmitted extends AuthEvent {
  final String email;
  final String password;

  const AuthLoginSubmitted({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}

class AuthVerifyEmailCheckRequested extends AuthEvent {}

class AuthResendVerificationRequested extends AuthEvent {}

class AuthCorrectEmailRequested extends AuthEvent {
  final String newEmail;

  const AuthCorrectEmailRequested(this.newEmail);

  @override
  List<Object?> get props => [newEmail];
}

class AuthPasswordResetRequested extends AuthEvent {
  final String email;

  const AuthPasswordResetRequested(this.email);

  @override
  List<Object?> get props => [email];
}

class AuthLogoutRequested extends AuthEvent {}

class AuthUserUpdated extends AuthEvent {
  final dynamic user;

  const AuthUserUpdated(this.user);

  @override
  List<Object?> get props => [user];
}
