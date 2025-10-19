import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/app_settings_repository.dart';
import '../../../data/models/app_settings_model.dart';
import 'app_settings_event.dart';
import 'app_settings_state.dart';

class AppSettingsBloc extends Bloc<AppSettingsEvent, AppSettingsState> {
  final AppSettingsRepository _repository;
  StreamSubscription<AppSettings>? _settingsSubscription;

  AppSettingsBloc({required AppSettingsRepository repository})
      : _repository = repository,
        super(const AppSettingsInitial()) {
    on<LoadAppSettings>(_onLoadAppSettings);
    on<SettingsUpdatedFromStream>(_onSettingsUpdated);
    on<UpdateCommunityToggle>(_onUpdateCommunityToggle);
  }

  Future<void> _onLoadAppSettings(
    LoadAppSettings event,
    Emitter<AppSettingsState> emit,
  ) async {
    try {
      emit(const AppSettingsLoading());

      // Initialize settings if needed
      await _repository.initializeSettings();

      // Load settings once
      final settings = await _repository.getAppSettings();
      emit(AppSettingsLoaded(settings: settings));

      // Cancel existing subscription if any
      await _settingsSubscription?.cancel();

      // Start listening for real-time updates
      print('AppSettingsBloc: Setting up stream subscription...');
      _settingsSubscription = _repository.getAppSettingsStream().listen(
        (settings) {
          print('AppSettingsBloc: Stream listener received update');
          print('AppSettingsBloc: Stream data isCommunityEnabled = ${settings.isCommunityEnabled}');
          add(SettingsUpdatedFromStream(settings));
        },
        onError: (error) {
          print('AppSettingsBloc: Stream error: $error');
        },
      );
      print('AppSettingsBloc: Stream subscription active');
    } catch (e) {
      print('AppSettingsBloc: Error loading settings: $e');
      emit(AppSettingsError(
        message: 'Failed to load settings: $e',
        lastKnownSettings: AppSettings.defaultSettings(),
      ));
    }
  }

  void _onSettingsUpdated(
    SettingsUpdatedFromStream event,
    Emitter<AppSettingsState> emit,
  ) {
    print('AppSettingsBloc: Received SettingsUpdatedFromStream event');
    print('AppSettingsBloc: isCommunityEnabled = ${event.settings.isCommunityEnabled}');
    print('AppSettingsBloc: Emitting AppSettingsLoaded state');
    emit(AppSettingsLoaded(settings: event.settings));
  }

  Future<void> _onUpdateCommunityToggle(
    UpdateCommunityToggle event,
    Emitter<AppSettingsState> emit,
  ) async {
    print('AppSettingsBloc: UpdateCommunityToggle event received');
    print('AppSettingsBloc: Requested isEnabled = ${event.isEnabled}');

    final currentState = state;
    final currentSettings = currentState is AppSettingsLoaded
        ? currentState.settings
        : AppSettings.defaultSettings();

    print('AppSettingsBloc: Current isCommunityEnabled = ${currentSettings.isCommunityEnabled}');

    try {
      print('AppSettingsBloc: Calling repository.updateCommunityToggle...');
      // Update in Firestore
      await _repository.updateCommunityToggle(
        isEnabled: event.isEnabled,
        adminId: event.adminId,
      );
      print('AppSettingsBloc: Repository update completed successfully');

      // IMMEDIATELY emit the new state - don't wait for stream
      final newSettings = currentSettings.copyWith(
        isCommunityEnabled: event.isEnabled,
        updatedAt: DateTime.now(),
        updatedBy: event.adminId,
      );
      print('AppSettingsBloc: Emitting new state with isCommunityEnabled = ${newSettings.isCommunityEnabled}');
      emit(AppSettingsLoaded(settings: newSettings));
    } catch (e) {
      print('AppSettingsBloc: Error updating community toggle: $e');

      // Show error and revert to previous state
      emit(AppSettingsError(
        message: 'Failed to update: $e',
        lastKnownSettings: currentSettings,
      ));

      // Restore previous state after showing error
      emit(AppSettingsLoaded(settings: currentSettings));
    }
  }

  @override
  Future<void> close() {
    _settingsSubscription?.cancel();
    return super.close();
  }
}
