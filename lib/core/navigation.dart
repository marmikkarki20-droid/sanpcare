import 'package:flutter/material.dart';

import '../app/care_scope.dart';
import '../screens/login_screen.dart';

void openScreen(BuildContext context, Widget screen) {
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
}

Future<void> signOutAndReturnToLogin(BuildContext context) async {
  final controller = CareScope.of(context);
  await controller.signOut();
  if (context.mounted) {
    await Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }
}

void showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
