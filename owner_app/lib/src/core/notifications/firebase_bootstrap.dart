import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';

import '../../config/app_config.dart';

const MethodChannel _notificationChannel =
    MethodChannel('qrmart_owner/notifications');

bool get isFirebaseConfigured =>
    AppConfig.firebaseApiKey.isNotEmpty &&
    AppConfig.firebaseProjectId.isNotEmpty &&
    AppConfig.firebaseMessagingSenderId.isNotEmpty &&
    AppConfig.firebaseAppId.isNotEmpty;

FirebaseOptions get _firebaseOptions => FirebaseOptions(
      apiKey: AppConfig.firebaseApiKey,
      appId: AppConfig.firebaseAppId,
      messagingSenderId: AppConfig.firebaseMessagingSenderId,
      projectId: AppConfig.firebaseProjectId,
      storageBucket: AppConfig.firebaseStorageBucket.isEmpty
          ? null
          : AppConfig.firebaseStorageBucket,
    );

Future<bool> ensureFirebaseInitialized() async {
  if (Firebase.apps.isNotEmpty) {
    return true;
  }

  try {
    await Firebase.initializeApp();
    return true;
  } catch (_) {
    if (!isFirebaseConfigured) {
      return false;
    }

    await Firebase.initializeApp(options: _firebaseOptions);
    return true;
  }
}

Future<void> ensureOwnerAlertsChannel() async {
  if (!Platform.isAndroid) {
    return;
  }

  await _notificationChannel.invokeMethod<void>('createNotificationChannel', {
    'id': AppConfig.ownerAlertsChannelId,
    'name': AppConfig.ownerAlertsChannelName,
    'description': AppConfig.ownerAlertsChannelDescription,
  });
}

Future<bool> ensureAndroidNotificationPermission() async {
  if (!Platform.isAndroid) {
    return true;
  }

  final granted = await _notificationChannel.invokeMethod<bool>(
    'ensureNotificationPermission',
  );
  return granted ?? false;
}

Future<void> openAndroidNotificationSettings() async {
  if (!Platform.isAndroid) {
    return;
  }

  await _notificationChannel.invokeMethod<void>('openNotificationSettings');
}

Future<void> showOwnerAlertNotification({
  required String title,
  required String body,
  String orderId = '',
}) async {
  if (!Platform.isAndroid) {
    return;
  }

  await ensureOwnerAlertsChannel();
  await _notificationChannel.invokeMethod<void>('showOrderNotification', {
    'channelId': AppConfig.ownerAlertsChannelId,
    'title': title,
    'body': body,
    'orderId': orderId,
  });
}

String _cleanDataValue(Map<String, dynamic> data, String key) {
  return (data[key] ?? '').toString().trim();
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  await ensureFirebaseInitialized();
  if (!Platform.isAndroid) {
    return;
  }

  final messageType = message.data['type']?.toString().toUpperCase() ?? '';
  if (messageType != 'NEW_ORDER') {
    return;
  }

  final dataTitle = _cleanDataValue(message.data, 'title');
  final dataBody = _cleanDataValue(message.data, 'body');
  final orderSummary = _cleanDataValue(message.data, 'orderSummary');
  final title = dataTitle.isNotEmpty
      ? dataTitle
      : (message.notification?.title?.trim().isNotEmpty ?? false)
          ? message.notification!.title!.trim()
          : 'New Order';
  final body = dataBody.isNotEmpty
      ? dataBody
      : (message.notification?.body?.trim().isNotEmpty ?? false)
          ? message.notification!.body!.trim()
          : (orderSummary.isNotEmpty
              ? orderSummary
              : 'A new order was received.');

  await showOwnerAlertNotification(
    title: title,
    body: body,
    orderId: _cleanDataValue(message.data, 'orderId'),
  );
}
