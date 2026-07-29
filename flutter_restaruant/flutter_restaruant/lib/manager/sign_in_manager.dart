import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_clz.dart';
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
  ///
  /// 這個呼叫位於 `main()` 的 `Future.wait` 啟動鏈上，因此**不可對外拋錯**：
  /// 讀取失敗（例如 prefs 檔損毀）若讓 Future 被 reject，`runApp()` 就不會
  /// 執行，App 開啟後只剩黑畫面。失敗時退回「非訪客」，最差情況是使用者
  /// 多看到一次登入頁，而不是整個 App 起不來。
  Future<void> loadGuestFlag() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isGuest = prefs.getBool(Constants.prefKeyGuestMode) ?? false;
    } on Exception catch (e, st) {
      logger.e('讀取訪客旗標失敗，退回非訪客', error: e, stackTrace: st);
      _isGuest = false;
    }
  }

  /// 標記為訪客。記憶體狀態只在寫入成功後才更新，避免磁碟寫入失敗時
  /// 記憶體與磁碟分歧——那會讓訪客身分在下次啟動時無聲消失。
  Future<void> markAsGuest() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(Constants.prefKeyGuestMode, true);
    _isGuest = true;
  }

  /// 清除訪客旗標。與 [markAsGuest] 相反的順序考量：先清記憶體，確保
  /// 即使磁碟移除失敗，當下的 [isGuest] 也不會仍回報 true。下次啟動時
  /// 殘留的磁碟值會讓使用者回到訪客身分，這比讓已登入者被當成訪客安全。
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
