import 'package:shared_preferences/shared_preferences.dart';

import 'apple_sign_in_manager.dart';
import 'auto_sign_in_manager.dart';
import 'biometric_sign_in_manager.dart';
import 'facebook_sign_in_manager.dart';
import 'google_sign_in_manager.dart';
import '../data_layer/dto/account_dto.dart';
import '../domain/entities/user_entity.dart';
import '../utils/constants.dart';
import '../utils/tuple.dart';

import 'mail_sign_in_up_manager.dart';

class SignInManager {
  static final SignInManager _singleton = SignInManager._internal();

  SignInManager._internal();

  factory SignInManager() => _singleton;

  AccountDto? accountDto;
  bool _isGuest = false;

  final GoogleSignInManager _googleSignInManager = GoogleSignInManager();
  final AppleSignInManager _appleSignInManager = AppleSignInManager();
  final FacebookSignInManager _facebookSignInManager = FacebookSignInManager();
  final MailSignInUpManager _mailSignInUpManager = MailSignInUpManager();
  final BiometricSignInManager _biometricAuthManager = BiometricSignInManager();
  final AutoSignInManager _autoSignInManager = AutoSignInManager();

  /// 訪客模式：未登入且已選擇以訪客身分瀏覽。與已登入狀態互斥。
  bool get isGuest => accountDto == null && _isGuest;

  /// 由 `main()` 於 `runApp` 前呼叫，把磁碟上的旗標讀進記憶體，
  /// 使 [isGuest] 能以同步方式被 UI 查詢。
  Future<void> loadGuestFlag() async {
    final prefs = await SharedPreferences.getInstance();
    _isGuest = prefs.getBool(Constants.prefKeyGuestMode) ?? false;
  }

  Future<void> markAsGuest() async {
    _isGuest = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(Constants.prefKeyGuestMode, true);
  }

  Future<void> clearGuestFlag() async {
    _isGuest = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(Constants.prefKeyGuestMode);
  }

  Future<Tuple2<AccountDto?, String>> signIn(AccountType accountType,
      {String mail = '', String passwd = ''}) async {
    Tuple2<AccountDto?, String> signInResult = const Tuple2(null, '');

    switch (accountType) {
      case AccountType.google:
        signInResult = await _googleSignInManager.signInWithGoogle();
        break;
      case AccountType.apple:
        signInResult = await _appleSignInManager.signInWithApple();
        break;
      case AccountType.facebook:
        signInResult = await _facebookSignInManager.signInWithFB();
        break;
      case AccountType.biometric:
        signInResult = await _biometricAuthManager.signInWithBiometric();
        break;
      case AccountType.auto:
        signInResult = await _autoSignInManager.signInWithAuto();
        break;
      case AccountType.mail:
      default:
        signInResult =
            await _mailSignInUpManager.signInWithMail(mail, passwd);
        break;
    }
    accountDto = signInResult.item1;
    // 所有登入路徑（Google / Apple / Facebook / Email / 自動 / 生物辨識）
    // 都匯流至此，是清除訪客旗標的單一收斂點。
    // 登入失敗時 accountDto 為 null，此時不可清除——否則訪客會因為
    // 一次失敗的登入嘗試而被踢回登入頁。
    if (accountDto != null) {
      await clearGuestFlag();
    }

    return signInResult;
  }

  Future<Tuple2<AccountDto?, String>> signUp(AccountType accountType,
      {required String mail, required String passwd}) async {
    Tuple2<AccountDto?, String> signUpResult = const Tuple2(null, '');

    switch (accountType) {
      case AccountType.mail:
      default:
        signUpResult =
            await _mailSignInUpManager.signUpWithMail(mail, passwd);
        break;
    }
    accountDto = signUpResult.item1;
    if (accountDto != null) {
      await clearGuestFlag();
    }

    return signUpResult;
  }

  Future<void> signOut() async {
    switch (accountDto?.type) {
      case AccountType.google:
        _googleSignInManager.signOutWithGoogle();
        break;
      case AccountType.apple:
        _appleSignInManager.signOutWithApple();
        break;
      case AccountType.facebook:
        _facebookSignInManager.signOutWithFB();
        break;
      case AccountType.mail:
      default:
        _mailSignInUpManager.signOutWithMail();
        break;
    }

    accountDto = null;
    // SettingsRepo.logout() 的 prefs.clear() 只清磁碟，不會清記憶體快取，
    // 因此這行不可省略——否則登出後 _isGuest 仍為 true，會被誤判為訪客。
    await clearGuestFlag();
  }
}
