import 'package:flutter/material.dart';

import '../controllers/care_controller.dart';
import '../data/care_repository.dart';
import '../screens/login_screen.dart';
import 'care_scope.dart';
import 'theme.dart';

class CareSnapApp extends StatefulWidget {
  const CareSnapApp({super.key, required this.repository});

  final CareRepository repository;

  @override
  State<CareSnapApp> createState() => _CareSnapAppState();
}

class _CareSnapAppState extends State<CareSnapApp> {
  late final CareController controller;

  @override
  void initState() {
    super.initState();
    controller = CareController(widget.repository);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CareScope(
      controller: controller,
      child: MaterialApp(
        title: 'CareSnap',
        debugShowCheckedModeBanner: false,
        theme: buildCareTheme(),
        home: const LoginScreen(),
      ),
    );
  }
}
