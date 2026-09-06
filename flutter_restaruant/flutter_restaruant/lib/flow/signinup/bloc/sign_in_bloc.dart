import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../domain/entities/entities_barrel.dart';
import '../../../domain/repositories/repositories_barrel.dart';
import '../../../features/utils/utils_barrel.dart';

part 'sign_in_event.dart';
part 'sign_in_state.dart';

class SignInBloc extends Bloc<SignInEvent, SignInState> {
  final SignInRepository _signInRepository;

  SignInBloc({required SignInRepository repository})
    : _signInRepository = repository,
      super(SignInInitial()) {
    on<SignInEvent>((event, emit) async {
      emit(const InProgress());

      final (AccountTypeModel type, bool isSignUp, String mail, String passwd) =
          switch (event) {
        GoogleSignInEvent() => (AccountTypeModel.google, false, '', ''),
        FacebookSignInEvent() => (AccountTypeModel.facebook, false, '', ''),
        AppleSignInEvent() => (AccountTypeModel.apple, false, '', ''),
        MailSignInEvent(:final mail, :final passwd) => (
            AccountTypeModel.mail,
            false,
            mail,
            passwd,
          ),
        MailSignUpEvent(:final mail, :final passwd) => (
            AccountTypeModel.mail,
            true,
            mail,
            passwd,
          ),
        BiometricSignInEvent() => (AccountTypeModel.biometric, false, '', ''),
        AutoSignInEvent() => (AccountTypeModel.auto, false, '', ''),
        _ => (AccountTypeModel.none, false, '', ''),
      };

      Tuple2<UserEntity?, String> result = await _signInRepository.signInUp(
        accountType: type,
        isSignUp: isSignUp,
        mail: mail,
        passwd: passwd,
      );
      UserEntity? userEntity = result.item1;

      if (userEntity != null) {
        if (event is! MailSignUpEvent) {
          emit(SignInSuccess(userEntity: userEntity));
        } else {
          emit(SignUpSuccess(userEntity: userEntity));
        }
      } else if (event is AutoSignInEvent) {
        // 自動登入失敗屬於正常情況（沒有既有憑證），僅回到初始狀態，
        // 不視為錯誤，避免使用者一進頁面就看到錯誤提示。
        emit(SignInInitial());
      } else {
        String errorMsg = result.item2;
        emit(Failure(errorMsg: errorMsg));
      }
    });
  }
}
