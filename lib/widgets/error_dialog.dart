import 'package:flutter/material.dart';

class ErrorDialog extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onPressed;
  final String buttonText;

  const ErrorDialog({
    super.key,
    this.title = 'Error',
    required this.message,
    this.onPressed,
    this.buttonText = 'OK',
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(
            Icons.error_outline,
            color: Color(0xFFE74C3C),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(title),
          ),
        ],
      ),
      content: Text(message),
      actions: [
        ElevatedButton(
          onPressed: onPressed ?? () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A5F7A),
          ),
          child: Text(buttonText),
        ),
      ],
    );
  }

  static void show(
    BuildContext context, {
    required String message,
    String title = 'Error',
    VoidCallback? onPressed,
    String buttonText = 'OK',
  }) {
    showDialog(
      context: context,
      builder: (context) => ErrorDialog(
        title: title,
        message: message,
        onPressed: onPressed ?? () => Navigator.pop(context),
        buttonText: buttonText,
      ),
    );
  }
}
