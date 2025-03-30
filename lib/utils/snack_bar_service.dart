import 'dart:async';

class SnackBarService {
  final StreamController<String> _snackBarController = StreamController.broadcast();

  /// Stream to listen for SnackBar messages
  Stream<String> get snackBarStream => _snackBarController.stream;

  /// Send a message to the SnackBar stream
  void showMessage(String message) {
    _snackBarController.add(message);
  }

  /// Dispose the StreamController
  void dispose() {
    _snackBarController.close();
  }
}