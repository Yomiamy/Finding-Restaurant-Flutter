import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_restaruant/flow/settings/repository/SettingsRepository.dart';

part 'SettingsEvent.dart';
part 'SettingsState.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {

  final SettingsRepository _settingsRepository;

  SettingsBloc({required SettingsRepository repository})
      : this._settingsRepository = repository,
        super(SettingsInitial()) {
    on<InitBioAuthSettingEvent>((event, emit) async {
      emit(InProgress());

      bool settingValue = await _settingsRepository.initBioAuthSetting();

      emit(InitBioAuthSettingState(settingValue: settingValue));
    });

    on<LogoutEvent>((event, emit) async {
      emit(InProgress());

      await _settingsRepository.logout();

      emit(LogoutSuccess());
    });

    on<ToggleBioAuthSettingEvent>((event, emit) async {
      bool settingValue = await _settingsRepository.toggleBioAuthSetting();

      emit(ToggleBioAuthSettingState(settingValue: settingValue));
    });
  }
}
