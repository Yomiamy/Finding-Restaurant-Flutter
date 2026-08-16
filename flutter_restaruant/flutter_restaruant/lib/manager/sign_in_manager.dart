import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_barrel.dart';
import 'apple_sign_in_manager.dart';
import 'auto_sign_in_manager.dart';
import 'biometric_sign_in_manager.dart';
import 'facebook_sign_in_manager.dart';
import 'google_sign_in_manager.dart';
import '../data_layer/dto/dto_barrel.dart';
import '../domain/entities/entities_barrel.dart';
import '../features/foundation/constants/constants_barrel.dart';
import '../features/utils/utils_barrel.dart';

import 'mail_sign_in_up_manager.dart';

class SignInManager {
  static final SignInManager _singleton = SignInManager._internal();

  SignInManager._internal();

  factory SignInManager() => _singleton;

  AccountDto? accountDto;

  /// 由 [loadPrefs] 於啟動時填入。`shared_preferences` 內部持有一份記憶體
  /// 快取，取得 instance 後 `getBool` 即為同步呼叫，因此不需要另外複製一份
  /// 旗標到本類別——多一份狀態只會多一個要維護的同步點。
  SharedPreferences? _prefs;

  final GoogleSignInManager _googleSignInManager = GoogleSignInManager();
  final AppleSignInManager _appleSignInManager = AppleSignInManager();
  final FacebookSignInManager _facebookSignInManager = FacebookSignInManager();
  final MailSignInUpManager _mailSignInUpManager = MailSignInUpManager();
  final BiometricSignInManager _biometricAuthManager = BiometricSignInManager();
  final AutoSignInManager _autoSignInManager = AutoSignInManager();

  /// 訪客模式：未登入且已選擇以訪客身分瀏覽。與已登入狀態互斥。
  ///
  /// [_prefs] 尚未載入時一律視為非訪客，最差情況是使用者多看到一次登入頁。
  bool get isGuest =>
      accountDto == null &&
      (_prefs?.getBool(Constants.prefKeyGuestMode) ?? false);

  /// 由 `main()` 於 `runApp` 前呼叫，使 [isGuest] 能以同步方式被 UI 查詢。
  ///
  /// 這個呼叫位於 `main()` 的 `Future.wait` 啟動鏈上，因此**不可對外拋錯**：
  /// 讀取失敗（例如 prefs 檔損毀）若讓 Future 被 reject，`runApp()` 就不會
  /// 執行，App 開啟後只剩黑畫面。
  Future<void> loadPrefs() async {
    try {
      _prefs = await SharedPreferences.getInstance();
    } on Exception catch (e, st) {
      logger.e('載入 SharedPreferences 失敗，訪客旗標將視為未設定', error: e, stackTrace: st);
    }
  }

  Future<void> markAsGuest() async =>
      await _prefs?.setBool(Constants.prefKeyGuestMode, true);

  Future<void> clearGuestFlag() async =>
      await _prefs?.remove(Constants.prefKeyGuestMode);

  Future<Tuple2<AccountDto?, String>> signIn(
    AccountType accountType, {
    String mail = '',
    String passwd = '',
  }) async {
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
        signInResult = await _mailSignInUpManager.signInWithMail(mail, passwd);
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

  Future<Tuple2<AccountDto?, String>> signUp(
    AccountType accountType, {
    required String mail,
    required String passwd,
  }) async {
    Tuple2<AccountDto?, String> signUpResult = const Tuple2(null, '');

    switch (accountType) {
      case AccountType.mail:
      default:
        signUpResult = await _mailSignInUpManager.signUpWithMail(mail, passwd);
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
    await clearGuestFlag();
  }
}
