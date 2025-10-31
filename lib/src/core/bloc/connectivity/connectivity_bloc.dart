import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../data/repositories/connectivity_repository.dart';
import 'connectivity_event.dart';
import 'connectivity_state.dart';

class ConnectivityBloc extends Bloc<ConnectivityEvent, ConnectivityState> {
  final ConnectivityRepository _connectivityRepository;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  ConnectivityBloc({required ConnectivityRepository connectivityRepository})
      : _connectivityRepository = connectivityRepository,
        super(const ConnectivityState()) {
    on<ConnectivityStarted>(_onConnectivityStarted);
    on<ConnectivityChanged>(_onConnectivityChanged);
  }

  Future<void> _onConnectivityStarted(
      ConnectivityStarted event, Emitter<ConnectivityState> emit) async {
    _connectivitySubscription = _connectivityRepository.connectivityStream.listen(
      (result) {
        final isConnected = result == ConnectivityResult.mobile ||
            result == ConnectivityResult.wifi ||
            result == ConnectivityResult.ethernet;
        add(ConnectivityChanged(isConnected: isConnected));
      },
    );
  }

  Future<void> _onConnectivityChanged(
      ConnectivityChanged event, Emitter<ConnectivityState> emit) async {
    final previousState = state;
    
    if (previousState.isConnected != event.isConnected) {
      emit(state.copyWith(
        isConnected: event.isConnected,
        showSnackbar: !event.isConnected,
      ));
    }
  }

  @override
  Future<void> close() {
    _connectivitySubscription?.cancel();
    return super.close();
  }
}
