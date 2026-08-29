import 'package:flutter/material.dart';

import '../../../features/foundation/style/style_barrel.dart';
import '../../../generated/l10n.dart';

/// 登入頁的帳密輸入表單。
///
/// `formKey` 由頁面持有，因為送出與驗證的時機由頁面的按鈕決定；本 widget
/// 只負責繪製欄位，並透過 [onEmailSaved] / [onPasswordSaved] 在 `save()`
/// 時把值回報給頁面。
class SignInFormWidget extends StatelessWidget {
  const SignInFormWidget({
    super.key,
    required this.formKey,
    required this.onEmailSaved,
    required this.onPasswordSaved,
  });

  final GlobalKey<FormState> formKey;
  final ValueChanged<String> onEmailSaved;
  final ValueChanged<String> onPasswordSaved;

  @override
  Widget build(BuildContext context) => Form(
    key: formKey,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        TextFormField(
          maxLines: 1,
          autofocus: false,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          decoration: InputDecoration(
            filled: true,
            prefixIcon: const Icon(Icons.email_outlined),
            hintText: S.current.email_invalid_hint_title,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ThemeSize.radius12),
            ),
          ),
          validator: (value) => (value == null || value.isEmpty)
              ? S.current.email_invalid_hint_msg
              : null,
          onSaved: (value) => onEmailSaved(value ?? ''),
        ),
        const SizedBox(height: ThemeSize.space15),
        TextFormField(
          maxLines: 1,
          obscureText: true,
          autofocus: false,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          decoration: InputDecoration(
            filled: true,
            prefixIcon: const Icon(Icons.lock_outline),
            hintText: S.current.passwd_invalid_hint_title,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ThemeSize.radius12),
            ),
          ),
          validator: (value) => (value == null || value.isEmpty)
              ? S.current.passwd_invalid_hint_msg
              : null,
          onSaved: (value) => onPasswordSaved(value ?? ''),
        ),
      ],
    ),
  );
}
