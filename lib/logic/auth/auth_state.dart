import 'package:equatable/equatable.dart';
import '../../data/models/user_model.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {
  final String? message;
  const AuthLoading({this.message});

  @override
  List<Object?> get props => [message];
}

class Authenticated extends AuthState {
  final UserModel user;

  const Authenticated(this.user);

  @override
  List<Object?> get props => [user];
}

class Unauthenticated extends AuthState {}

class AuthActionSuccess extends AuthState {
  final String message;
  final UserModel? user;

  const AuthActionSuccess(this.message, {this.user});

  @override
  List<Object?> get props => [message, user];
}

class AuthFailure extends AuthState {
  final String message;
  final String? field;

  const AuthFailure(this.message, {this.field});

  @override
  List<Object?> get props => [message, field];
}
