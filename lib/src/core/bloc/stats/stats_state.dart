import 'package:equatable/equatable.dart';
import '../../../data/models/stats_model.dart';

abstract class StatsState extends Equatable {
  const StatsState();

  @override
  List<Object?> get props => [];
}

class StatsInitial extends StatsState {}

class StatsLoading extends StatsState {}

class AppStatsLoaded extends StatsState {
  final AppStats appStats;

  const AppStatsLoaded({required this.appStats});

  @override
  List<Object?> get props => [appStats];
}

class UserProgressDetailLoaded extends StatsState {
  final UserProgressDetail userProgressDetail;

  const UserProgressDetailLoaded({required this.userProgressDetail});

  @override
  List<Object?> get props => [userProgressDetail];
}

class AllUsersStatsLoaded extends StatsState {
  final List<UserStats> usersStats;

  const AllUsersStatsLoaded({required this.usersStats});

  @override
  List<Object?> get props => [usersStats];
}

class StatsError extends StatsState {
  final String message;

  const StatsError({required this.message});

  @override
  List<Object?> get props => [message];
}
