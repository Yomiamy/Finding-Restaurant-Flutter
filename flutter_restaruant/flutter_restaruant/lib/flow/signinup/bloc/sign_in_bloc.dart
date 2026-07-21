import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_restaruant/flow/signinup/repository/sign_in_repository.dart';
import 'package:flutter_restaruant/model/account_info.dart';
import 'package:flutter_restaruant/utils/tuple.dart';

part 'sign_in_event.dart';

part 'sign_in_state.dart';

class SignInBloc extends Bloc<SignInEvent, SignInState> {
  final SignInRepository _signInRepository;

  SignInBloc({required SignInRepository repository})
      : this._signInRepository = repository,
        super(SignInInitial()) {
    on<SignInEvent>((event, emit) async {
      emit(InProgress());

      Tuple2<AccountInfo?, String> result =
          await this._signInRepository.signInUp(event);
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
