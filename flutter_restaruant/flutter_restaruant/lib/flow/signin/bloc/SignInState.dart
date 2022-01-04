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

class Success extends SignInState {

  final AccountInfo accountInfo;

  Success({required this.accountInfo});

  @override
  List<Object> get props => [this.accountInfo.hashCode];
}

class Failure extends SignInState {
  final SignInEvent event;

  Failure({required this.event});

  @override
  List<Object> get props => [this.event];
}
