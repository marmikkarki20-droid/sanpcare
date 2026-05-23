import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';

String friendlyError(Object exception) {
  if (exception is firebase_auth.FirebaseAuthException) {
    return switch (exception.code) {
      'user-not-found' ||
      'wrong-password' ||
      'invalid-credential' => 'Invalid email or password.',
      'network-request-failed' =>
        'Network connection failed. Please try again.',
      _ => exception.message ?? 'Authentication failed.',
    };
  }
  if (exception is FirebaseException) {
    return exception.message ?? 'Firebase request failed.';
  }
  if (exception is PlatformException) {
    return switch (exception.code) {
      'camera_access_denied' =>
        'Camera permission is required to take a photo.',
      'photo_access_denied' || 'photos_access_denied' =>
        'Photo library permission is required to choose an image.',
      _ => exception.message ?? 'Unable to access image evidence.',
    };
  }
  return exception
      .toString()
      .replaceFirst('Bad state: ', '')
      .replaceFirst('Exception: ', '');
}
