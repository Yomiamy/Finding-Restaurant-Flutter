part of 'SettingsBloc.dart';

abstract class SettingsState extends Equatable {

  const SettingsState();

  @override
  List<Object> get props => [];
}

class SettingsInitial extends SettingsState {

  @override
  String toString() => "SettingsInitial";

  @override
  List<Object> get props => [];
}

class InProgress extends SettingsState {

  const InProgress();

  @override
  String toString() => "InProgress";

  @override
  List<Object> get props => [];
}

class LogoutSuccess extends SettingsState {

  const LogoutSuccess();

  @override
  String toString() => "LogoutSuccess";

  @override
  List<Object> get props => [];
}

class AccountRemovalSuccessState extends SettingsState {

  const AccountRemovalSuccessState();

  @override
  String toString() => "AccountRemovalSuccess";

  @override
  List<Object> get props => [];
}

class InitBioAuthSettingState extends SettingsState {

  final bool settingValue;

  const InitBioAuthSettingState({required this.settingValue});

  @override
  String toString() => "InitBioAuthSettingState";

  @override
  List<Object> get props => [settingValue];
}

class ToggleBioAuthSettingState extends SettingsState {

  final bool settingValue;

  const ToggleBioAuthSettingState({required this.settingValue});

  @override
  String toString() => "ToggleBioAuthSettingState";

  @override
  List<Object> get props => [settingValue];
}
