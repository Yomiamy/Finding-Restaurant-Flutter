import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../domain/repositories/repositories_barrel.dart';

part 'settings_event.dart';
part 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final SettingsRepository _settingsRepository;

  SettingsBloc({required SettingsRepository repository})
      : _settingsRepository = repository,
        super(SettingsInitial()) {
    on<InitBioAuthSettingEvent>((event, emit) async {
      emit(const InProgress());

      bool settingValue = await _settingsRepository.initBioAuthSetting();

      emit(InitBioAuthSettingState(settingValue: settingValue));
    });

    on<ToggleBioAuthSettingEvent>((event, emit) async {
      bool settingValue = await _settingsRepository.toggleBioAuthSetting();

      emit(ToggleBioAuthSettingState(settingValue: settingValue));
    });

    on<LogoutEvent>((event, emit) async {
      emit(const InProgress());

      await _settingsRepository.logout();

      emit(const LogoutSuccess());
    });

    on<AccountRemovalEvent>((event, emit) async {
      emit(const InProgress());

      await _settingsRepository.removeAccount(event.subject, event.bodyPrefix);

      emit(const AccountRemovalSuccessState());
    });
  }
}
