import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

class FacebookSignInManager {

  static final FacebookSignInManager _singleton = FacebookSignInManager._internal();

  FacebookSignInManager._internal();

  factory FacebookSignInManager() => _singleton;

  Future<String> signInWithFB() async {
    // Trigger the sign-in flow
    final LoginResult loginResult = await FacebookAuth.instance.login();

    // Create a credential from the access token
    final OAuthCredential facebookAuthCredential = FacebookAuthProvider.credential(loginResult.accessToken!.token);

    // Once signed in, return the UserCredential
    UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(facebookAuthCredential);
    return userCredential.user?.uid ?? "";
  }

  void signInOutWithFB() async => await FacebookAuth.instance.logOut();
}