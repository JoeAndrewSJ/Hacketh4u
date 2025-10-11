import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityRepository {
  final Connectivity _connectivity;

  ConnectivityRepository(this._connectivity);

  Stream<ConnectivityResult> get connectivityStream =>
      _connectivity.onConnectivityChanged;

  Future<ConnectivityResult> checkConnectivity() async {
    return await _connectivity.checkConnectivity();
  }
}
