import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_restaruant/flow/signinup/repository/SignInRepository.dart';
import 'package:flutter_restaruant/model/AccountInfo.dart';
import 'package:flutter_restaruant/utils/Tuple.dart';

part 'SignInEvent.dart';

part 'SignInState.dart';

class SignInBloc extends Bloc<SignInEvent, SignInState> {

  final SignInRepository _signInRepository;

  SignInBloc({required SignInRepository repository})
      : this._signInRepository = repository,
        super(SignInInitial()) {
    on<SignInEvent>((event, emit) async {
      emit(InProgress());

      Tuple2<AccountInfo?, String> result = await this._signInRepository.signInUp(event);
      AccountInfo? accountInfo = result.item1;

      if (accountInfo != null) {
        if (event is! MailSignUpEvent) {
          emit(SignInSuccess(accountInfo: accountInfo));
        } else {
          emit(SignUpSuccess(accountInfo: accountInfo));
        }
      } else {
        String errorMsg = result.item2;
        emit(Failure(errorMsg: errorMsg));
      }
    });
  }
}
