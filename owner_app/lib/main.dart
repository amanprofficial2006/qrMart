import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'src/core/notifications/firebase_bootstrap.dart';
import 'src/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final firebaseReady = await ensureFirebaseInitialized();
  if (firebaseReady) {
    await ensureOwnerAlertsChannel();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }
  runApp(const QrMartOwnerBootstrap());
}
