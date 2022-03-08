part of 'SignInBloc.dart';

abstract class SignInEvent extends Equatable {
  const SignInEvent();

  @override
  List<Object> get props => [];
}

class MailSignInEvent extends SignInEvent {

  final String mail;
  final String passwd;

  MailSignInEvent({required this.mail, required this.passwd});

  @override
  String toString() => "MailSignIn event.";
}

class MailSignUpEvent extends SignInEvent {

  final String mail;
  final String passwd;

  MailSignUpEvent({required this.mail, required this.passwd});

  @override
  String toString() => "MailSignUp event.";
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

class BiometricAuthEvent extends SignInEvent {
  @override
  String toString() => "MailSignIn event.";
}
