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
        super(SettingsInitial());

  @override
  Stream<SettingsState> mapEventToState(SettingsEvent event) {
    return Stream.empty();
  }
}
