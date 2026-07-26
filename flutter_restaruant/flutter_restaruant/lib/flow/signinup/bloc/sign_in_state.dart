part of 'sign_in_bloc.dart';

abstract class SignInState extends Equatable {
  const SignInState();

  @override
  List<Object> get props => [];
}

class SignInInitial extends SignInState {}

class InProgress extends SignInState {
  const InProgress();

  @override
  String toString() => 'Loading detail info';
}

class SignInSuccess extends SignInState {
  final UserEntity userEntity;

  const SignInSuccess({required this.userEntity});

  @override
  List<Object> get props => [userEntity.hashCode];
}

class SignUpSuccess extends SignInState {
  final UserEntity userEntity;

  const SignUpSuccess({required this.userEntity});

  @override
  List<Object> get props => [userEntity.hashCode];
}

class Failure extends SignInState {
  final String errorMsg;

  const Failure({required this.errorMsg});

  @override
  List<Object> get props => [errorMsg];
}
