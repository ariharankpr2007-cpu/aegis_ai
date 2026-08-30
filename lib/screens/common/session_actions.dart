import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SessionActions {
  const SessionActions._();

  static Future<void> confirmLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You will return to the login screen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );

    if (shouldLogout != true || !context.mounted) return;

    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;

    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  static Future<bool> confirmExit(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Exit AEGIS AI?'),
            content: const Text('Do you want to close the app?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Stay'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Exit'),
              ),
            ],
          ),
        ) ??
        false;
  }
}
