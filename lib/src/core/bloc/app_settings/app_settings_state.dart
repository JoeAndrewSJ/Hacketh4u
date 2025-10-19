import 'package:equatable/equatable.dart';
import '../../../data/models/app_settings_model.dart';

abstract class AppSettingsState extends Equatable {
  const AppSettingsState();

  @override
  List<Object?> get props => [];
}

class AppSettingsInitial extends AppSettingsState {
  const AppSettingsInitial();
}

class AppSettingsLoading extends AppSettingsState {
  const AppSettingsLoading();
}

class AppSettingsLoaded extends AppSettingsState {
  final AppSettings settings;

  const AppSettingsLoaded({required this.settings});

  @override
  List<Object?> get props => [settings.isCommunityEnabled, settings.updatedAt];
}

class AppSettingsUpdating extends AppSettingsState {
  final AppSettings currentSettings;

  const AppSettingsUpdating({required this.currentSettings});

  @override
  List<Object?> get props => [currentSettings];
}

class AppSettingsError extends AppSettingsState {
  final String message;
  final AppSettings? lastKnownSettings;

  const AppSettingsError({
    required this.message,
    this.lastKnownSettings,
  });

  @override
  List<Object?> get props => [message, lastKnownSettings];
}
