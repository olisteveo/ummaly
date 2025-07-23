import 'package:flutter/material.dart';

class SnackbarHelper {
  static void show(
      BuildContext context,
      String message, {
        Color backgroundColor = Colors.green,
        Duration duration = const Duration(seconds: 3),
      }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: backgroundColor,
          duration: duration,
        ),
      );
    });
  }
}
