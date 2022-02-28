part of 'SettingsBloc.dart';

abstract class SettingsState extends Equatable {

  const SettingsState();

  @override
  List<Object> get props => [];
}

class SettingsInitial extends SettingsState {
  @override
  List<Object> get props => [];
}

class InProgress extends SettingsState {

  const InProgress();

  @override
  String toString() => "InProgress";
}

class LogoutSuccess extends SettingsState {

  const LogoutSuccess();

  @override
  String toString() => "LogoutSuccess";
}
