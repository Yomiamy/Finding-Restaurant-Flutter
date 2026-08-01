import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../domain/repositories/sign_in_repository.dart';
import '../../../domain/entities/user_entity.dart';
import '../../../features/utils/app_utils.dart';

part 'sign_in_event.dart';

part 'sign_in_state.dart';

class SignInBloc extends Bloc<SignInEvent, SignInState> {
  final SignInRepository _signInRepository;

  SignInBloc({required SignInRepository repository})
      : _signInRepository = repository,
        super(SignInInitial()) {
    on<SignInEvent>((event, emit) async {
      emit(const InProgress());

      AccountType type;
      bool isSignUp = false;
      String mail = '';
      String passwd = '';

      if (event is GoogleSignInEvent) {
        type = AccountType.google;
      } else if (event is FacebookSignInEvent) {
        type = AccountType.facebook;
      } else if (event is AppleSignInEvent) {
        type = AccountType.apple;
      } else if (event is MailSignInEvent) {
        type = AccountType.mail;
        mail = event.mail;
        passwd = event.passwd;
      } else if (event is MailSignUpEvent) {
        type = AccountType.mail;
        isSignUp = true;
        mail = event.mail;
        passwd = event.passwd;
      } else if (event is BiometricSignInEvent) {
        type = AccountType.biometric;
      } else if (event is AutoSignInEvent) {
        type = AccountType.auto;
      } else {
        type = AccountType.none;
      }

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
