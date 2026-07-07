import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Service for monitoring network connectivity
class ConnectivityService {
  final _connectivity = Connectivity();

  /// Stream of connectivity status
  Stream<bool> get isOnlineStream => _connectivity.onConnectivityChanged.map(
        (results) => results.isNotEmpty && !results.contains(ConnectivityResult.none),
      );

  /// Check current connectivity status
  Future<bool> get isOnline async {
    final results = await _connectivity.checkConnectivity();
    return results.isNotEmpty && !results.contains(ConnectivityResult.none);
  }
}

/// Provider for connectivity service
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService();
});

/// Provider for connectivity status stream
final connectivityProvider = StreamProvider<bool>((ref) {
  return ref.read(connectivityServiceProvider).isOnlineStream;
});
