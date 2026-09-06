import 'package:json_annotation/json_annotation.dart';

enum AccountType {
  @JsonValue('GOOGLE')
  google,
  @JsonValue('FACEBOOK')
  facebook,
  @JsonValue('APPLE')
  apple,
  @JsonValue('MAIL')
  mail,
  @JsonValue('BIOMETRIC')
  biometric,
  @JsonValue('AUTO')
  auto,
  @JsonValue('NONE')
  none,
}
