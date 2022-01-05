part of 'SignInBloc.dart';

abstract class SignInEvent extends Equatable {
  const SignInEvent();

  @override
  List<Object> get props => [];
}

class GoogleSignInEvent extends SignInEvent {
  @override
  String toString() => "GoogleSignIn event.";
}

class FacebookSignInEvent extends SignInEvent {
  @override
  String toString() => "FacebookSignIn event.";
}

class AppleSignInEvent extends SignInEvent {
  @override
  String toString() => "AppleSignIn event.";
}
