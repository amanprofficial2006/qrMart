class AppConfig {
  static const appName = 'qrMart';
  static const productionApiBaseUrl = 'https://qrmart.onrender.com';
  static const apiBaseUrl = productionApiBaseUrl;

  static const googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue:
        '326409235411-m2v9butg0bib4vhkl3sb8vdqat6hghsu.apps.googleusercontent.com',
  );
  static const firebaseApiKey = String.fromEnvironment(
    'FIREBASE_API_KEY',
    defaultValue: 'AIzaSyBEd31CoL3fpBRQSfBJP9u2K4gVSZe0zno',
  );
  static const firebaseProjectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
    defaultValue: 'qrmart-fc52c',
  );
  static const firebaseMessagingSenderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
    defaultValue: '51233536961',
  );
  static const firebaseStorageBucket = String.fromEnvironment(
    'FIREBASE_STORAGE_BUCKET',
    defaultValue: 'qrmart-fc52c.firebasestorage.app',
  );
  static const firebaseAppId = String.fromEnvironment(
    'FIREBASE_APP_ID',
    defaultValue: '',
  );
  static const ownerAlertsChannelId = 'orders_alerts_v2';
  static const ownerAlertsChannelName = 'Order alerts';
  static const ownerAlertsChannelDescription =
      'Alerts and background notifications for new customer orders.';
}
