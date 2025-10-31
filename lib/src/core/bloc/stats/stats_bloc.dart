import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/stats_repository.dart';
import '../../../data/models/stats_model.dart';
import 'stats_event.dart';
import 'stats_state.dart';

class StatsBloc extends Bloc<StatsEvent, StatsState> {
  final StatsRepository _statsRepository;

  StatsBloc({required StatsRepository statsRepository})
      : _statsRepository = statsRepository,
        super(StatsInitial()) {
    
    on<LoadAppStats>(_onLoadAppStats);
    on<LoadUserProgressDetail>(_onLoadUserProgressDetail);
    on<LoadAllUsersStats>(_onLoadAllUsersStats);
    on<RefreshStats>(_onRefreshStats);
  }

  Future<void> _onLoadAppStats(LoadAppStats event, Emitter<StatsState> emit) async {
    try {
      emit(StatsLoading());
      final appStats = await _statsRepository.getAppStats();
      emit(AppStatsLoaded(appStats: appStats));
    } catch (e) {
      emit(StatsError(message: e.toString()));
    }
  }

  Future<void> _onLoadUserProgressDetail(LoadUserProgressDetail event, Emitter<StatsState> emit) async {
    try {
      emit(StatsLoading());
      final userProgressDetail = await _statsRepository.getUserProgressDetail(event.userId);
      emit(UserProgressDetailLoaded(userProgressDetail: userProgressDetail));
    } catch (e) {
      emit(StatsError(message: e.toString()));
    }
  }

  Future<void> _onLoadAllUsersStats(LoadAllUsersStats event, Emitter<StatsState> emit) async {
    try {
      emit(StatsLoading());
      final usersStats = await _statsRepository.getAllUsersStats();
      emit(AllUsersStatsLoaded(usersStats: usersStats));
    } catch (e) {
      emit(StatsError(message: e.toString()));
    }
  }

  Future<void> _onRefreshStats(RefreshStats event, Emitter<StatsState> emit) async {
    // Reload the current state type
    if (state is AppStatsLoaded) {
      add(const LoadAppStats());
    } else if (state is AllUsersStatsLoaded) {
      add(const LoadAllUsersStats());
    } else {
      add(const LoadAppStats());
    }
  }
}
