import 'package:flutter/material.dart';

Future<String?> showEncryptedBackupPinDialog(
  BuildContext context, {
  String title = 'Create encrypted backup',
  String description =
      'Use a PIN of at least 6 characters. Noor cannot recover a forgotten PIN.',
  String actionLabel = 'Create backup',
}) async {
  final pin = TextEditingController();
  final confirmation = TextEditingController();
  String? error;
  try {
    return await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(description),
              const SizedBox(height: 16),
              TextField(
                controller: pin,
                obscureText: true,
                autocorrect: false,
                enableSuggestions: false,
                decoration: const InputDecoration(labelText: 'Backup PIN'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmation,
                obscureText: true,
                autocorrect: false,
                enableSuggestions: false,
                onSubmitted: (_) {},
                decoration: InputDecoration(
                  labelText: 'Confirm PIN',
                  errorText: error,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (pin.text.length < 6) {
                  setDialogState(
                    () => error = 'PIN must have at least 6 characters.',
                  );
                } else if (pin.text != confirmation.text) {
                  setDialogState(() => error = 'PINs do not match.');
                } else {
                  Navigator.pop(dialogContext, pin.text);
                }
              },
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  } finally {
    pin.dispose();
    confirmation.dispose();
  }
}

Future<String?> showEncryptedBackupUnlockDialog(BuildContext context) async {
  final pin = TextEditingController();
  String? error;
  try {
    return await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Unlock encrypted backup'),
          content: TextField(
            controller: pin,
            obscureText: true,
            autocorrect: false,
            enableSuggestions: false,
            decoration: InputDecoration(
              labelText: 'Backup PIN',
              errorText: error,
            ),
            onSubmitted: (value) {
              if (value.length < 6) {
                setDialogState(() => error = 'Enter your backup PIN.');
              } else {
                Navigator.pop(dialogContext, value);
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (pin.text.length < 6) {
                  setDialogState(() => error = 'Enter your backup PIN.');
                } else {
                  Navigator.pop(dialogContext, pin.text);
                }
              },
              child: const Text('Unlock'),
            ),
          ],
        ),
      ),
    );
  } finally {
    pin.dispose();
  }
}
