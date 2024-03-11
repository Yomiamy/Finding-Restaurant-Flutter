part of 'SettingsBloc.dart';

abstract class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object> get props => [];
}

class InitBioAuthSettingEvent extends SettingsEvent {

  const InitBioAuthSettingEvent();

  @override
  List<Object> get props => [];
}

class ToggleBioAuthSettingEvent extends SettingsEvent {

  const ToggleBioAuthSettingEvent();

  @override
  List<Object> get props => [];
}

class LogoutEvent extends SettingsEvent {

  const LogoutEvent();

  @override
  List<Object> get props => [];
}

class AccountRemovalEvent extends SettingsEvent {

  final String subject;
  final String bodyPrefix;

  const AccountRemovalEvent({required this.subject, required this.bodyPrefix});

  @override
  List<Object> get props => [];
}
