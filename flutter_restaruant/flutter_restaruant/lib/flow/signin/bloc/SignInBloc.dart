import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_restaruant/flow/signin/repository/SignInRepository.dart';
import 'package:flutter_restaruant/model/AccountInfo.dart';

part 'SignInEvent.dart';

part 'SignInState.dart';

class SignInBloc extends Bloc<SignInEvent, SignInState> {
  final SignInRepository _signInRepository;

  SignInBloc({required SignInRepository repository})
      : this._signInRepository = repository,
        super(SignInInitial());

  @override
  Stream<SignInState> mapEventToState(SignInEvent event) async* {
    yield* _mapSignInToState(event);
  }

  Stream<SignInState> _mapSignInToState(SignInEvent event) async* {
    yield InProgress();

    AccountInfo? accountInfo = await this._signInRepository.signIn(event);

    if (accountInfo != null) {
      if (event is! MailSignUpEvent) {
        yield SignInSuccess(accountInfo: accountInfo);
      } else {
        yield SignUpSuccess(accountInfo: accountInfo);
      }
    } else {
      yield Failure(event: event);
    }
  }
}
