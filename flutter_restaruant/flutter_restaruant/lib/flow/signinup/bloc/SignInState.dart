part of 'SignInBloc.dart';

abstract class SignInState extends Equatable {
  const SignInState();

  @override
  List<Object> get props => [];
}

class SignInInitial extends SignInState {}

class InProgress extends SignInState {
  const InProgress();

  @override
  String toString() => "Loading detail info";
}

class SignInSuccess extends SignInState {
  final AccountInfo accountInfo;

  SignInSuccess({required this.accountInfo});

  @override
  List<Object> get props => [this.accountInfo.hashCode];
}

class SignUpSuccess extends SignInState {
  final AccountInfo accountInfo;

  SignUpSuccess({required this.accountInfo});

  @override
  List<Object> get props => [this.accountInfo.hashCode];
}

class Failure extends SignInState {
  final String errorMsg;

  Failure({required this.errorMsg});

  @override
  List<Object> get props => [this.errorMsg];
}
