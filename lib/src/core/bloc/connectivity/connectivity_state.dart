import 'package:equatable/equatable.dart';

class ConnectivityState extends Equatable {
  final bool isConnected;
  final bool showSnackbar;

  const ConnectivityState({
    this.isConnected = true,
    this.showSnackbar = false,
  });

  ConnectivityState copyWith({
    bool? isConnected,
    bool? showSnackbar,
  }) {
    return ConnectivityState(
      isConnected: isConnected ?? this.isConnected,
      showSnackbar: showSnackbar ?? this.showSnackbar,
    );
  }

  @override
  List<Object> get props => [isConnected, showSnackbar];
}



