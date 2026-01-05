import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class SnackbarService {
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  void showSuccess(String message) {
    _show(
      message,
      backgroundColor: Colors.green.shade800,
      icon: Icons.check_circle_outline,
    );
  }

  void showError(String message) {
    _show(
      message,
      backgroundColor: Colors.red.shade800,
      icon: Icons.error_outline,
    );
  }

  void showInfo(String message) {
    _show(
      message,
      backgroundColor: Colors.blue.shade800,
      icon: Icons.info_outline,
    );
  }

  void _show(
    String message, {
    required Color backgroundColor,
    required IconData icon,
  }) {
    scaffoldMessengerKey.currentState?.removeCurrentSnackBar();
    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
