import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app/care_snap_app.dart';
import 'data/care_repository.dart';
import 'data/demo_care_repository.dart';
import 'data/firebase_care_repository.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  CareRepository repository;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    repository = FirebaseCareRepository();
  } catch (_) {
    repository = DemoCareRepository();
  }

  runApp(CareSnapApp(repository: repository));
}
