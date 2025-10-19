import 'package:equatable/equatable.dart';
import '../../../data/models/app_settings_model.dart';

abstract class AppSettingsEvent extends Equatable {
  const AppSettingsEvent();

  @override
  List<Object?> get props => [];
}

class LoadAppSettings extends AppSettingsEvent {
  const LoadAppSettings();
}

class UpdateCommunityToggle extends AppSettingsEvent {
  final bool isEnabled;
  final String? adminId;

  const UpdateCommunityToggle({
    required this.isEnabled,
    this.adminId,
  });

  @override
  List<Object?> get props => [isEnabled, adminId];
}

// Internal event - triggered by stream updates (not exposed to UI)
class SettingsUpdatedFromStream extends AppSettingsEvent {
  final AppSettings settings;

  const SettingsUpdatedFromStream(this.settings);

  @override
  List<Object?> get props => [settings];
}
