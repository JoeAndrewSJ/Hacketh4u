import 'package:equatable/equatable.dart';

abstract class StatsEvent extends Equatable {
  const StatsEvent();

  @override
  List<Object?> get props => [];
}

class LoadAppStats extends StatsEvent {
  const LoadAppStats();
}

class LoadUserProgressDetail extends StatsEvent {
  final String userId;

  const LoadUserProgressDetail({required this.userId});

  @override
  List<Object?> get props => [userId];
}

class LoadAllUsersStats extends StatsEvent {
  const LoadAllUsersStats();
}

class RefreshStats extends StatsEvent {
  const RefreshStats();
}
