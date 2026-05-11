import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../core/notifications/firebase_bootstrap.dart';
import '../../core/network/api_exception.dart';
import '../../core/utils/formatters.dart';
import '../../models/order.dart';
import '../../models/owner.dart';
import '../../models/product.dart';
import '../../models/qr_info.dart';
import '../../models/shop.dart';
import '../auth/session_controller.dart';
import 'owner_repository.dart';

class DashboardController extends ChangeNotifier {
  static const Duration _alertDedupeWindow = Duration(seconds: 15);

  DashboardController({
    required OwnerRepository repository,
    required SessionController sessionController,
  })  : _repository = repository,
        _sessionController = sessionController;

  final OwnerRepository _repository;
  final SessionController _sessionController;

  bool loading = true;
  bool mutating = false;
  bool liveAlertsConnected = false;
  bool notificationsBusy = false;
  bool notificationsSupported = false;
  bool notificationPermissionGranted = false;
  bool backgroundNotificationsEnabled = false;
  String? error;
  String? notice;
  String? notificationStatus;
  Owner? owner;
  Shop? shop;
  List<Product> products = const <Product>[];
  List<Order> orders = const <Order>[];
  QrInfo? qrInfo;
  String qrBaseUrl = '';
  DateTime? lastOrderAlertAt;
  String? lastOrderAlertOrderNumber;

  Timer? _orderPollingTimer;
  bool _pollingOrders = false;
  Set<String> _knownOrderIds = <String>{};
  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<RemoteMessage>? _foregroundMessageSubscription;
  StreamSubscription<RemoteMessage>? _messageOpenedSubscription;
  bool _notificationsInitialized = false;
  final Map<String, DateTime> _recentAlertKeys = <String, DateTime>{};

  List<Order> get activeOrders => orders
      .where((order) => !const {'completed', 'rejected', 'cancelled'}.contains(order.status))
      .toList(growable: false);

  List<Order> get historyOrders => orders
      .where((order) => const {'completed', 'rejected', 'cancelled'}.contains(order.status))
      .toList(growable: false);

  double get todayRevenue {
    final now = DateTime.now();

    return orders
        .where((order) =>
            order.createdAt != null &&
            order.createdAt!.year == now.year &&
            order.createdAt!.month == now.month &&
            order.createdAt!.day == now.day &&
            !const {'rejected', 'cancelled'}.contains(order.status))
        .fold<double>(0, (sum, order) => sum + order.totalAmount);
  }

  Future<void> load({bool showLoader = true}) async {
    if (showLoader) {
      loading = true;
    }

    error = null;
    notifyListeners();

    try {
      final identity = await _repository.getIdentity();
      final results = await Future.wait<dynamic>([
        _repository.listProducts(),
        _repository.listOrders(),
        _repository.getQr(),
      ]);

      owner = identity.owner;
      shop = identity.shop;
      products = results[0] as List<Product>;
      orders = results[1] as List<Order>;
      qrInfo = results[2] as QrInfo;
      qrBaseUrl = _extractBaseUrl(qrInfo?.qrUrl ?? shop?.qrUrl ?? '');
      _knownOrderIds = orders.map((order) => order.id).toSet();
      _ensureLiveAlerts();
      await _initializeNotifications();
      _sessionController.replaceIdentity(identity);
    } catch (exception) {
      error = _messageFrom(exception);
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> refreshOrders() async {
    try {
      error = null;
      final latestOrders = await _repository.listOrders();
      _applyOrders(latestOrders, alertOnNew: false);
      liveAlertsConnected = true;
    } catch (exception) {
      error = _messageFrom(exception);
      liveAlertsConnected = false;
    } finally {
      notifyListeners();
    }
  }

  Future<void> reconnectLiveAlerts() async {
    await refreshOrders();
    _ensureLiveAlerts();
  }

  Future<void> enableBackgroundNotifications() async {
    notificationsBusy = true;
    error = null;
    notifyListeners();

    try {
      final ready = await ensureFirebaseInitialized();
      notificationsSupported = ready;

      if (!ready) {
        notificationStatus =
            'Firebase notifications are not configured for this app build yet.';
        backgroundNotificationsEnabled = false;
        return;
      }

      await ensureOwnerAlertsChannel();
      if (defaultTargetPlatform == TargetPlatform.android) {
        notificationPermissionGranted =
            await ensureAndroidNotificationPermission();
      } else {
        final settings = await FirebaseMessaging.instance.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
        notificationPermissionGranted =
            settings.authorizationStatus == AuthorizationStatus.authorized ||
            settings.authorizationStatus == AuthorizationStatus.provisional;
      }

      if (!notificationPermissionGranted) {
        backgroundNotificationsEnabled = false;
        notificationStatus = defaultTargetPlatform == TargetPlatform.android
            ? 'Android notification settings khol di gayi hain. Alerts aur sound allow karke app me wapas aaiye.'
            : 'Notification permission not granted on this device.';
        if (defaultTargetPlatform == TargetPlatform.android) {
          await openAndroidNotificationSettings();
        }
        return;
      }

      final token = await FirebaseMessaging.instance.getToken();

      if (token == null || token.isEmpty) {
        backgroundNotificationsEnabled = false;
        notificationStatus = 'Could not create a notification token for this device.';
        return;
      }

      await _repository.registerDevice(
        fcmToken: token,
        platform: defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
      );

      backgroundNotificationsEnabled = true;
      notificationStatus = 'Background order notifications enabled on this device.';
    } catch (exception) {
      backgroundNotificationsEnabled = false;
      notificationStatus = _messageFrom(exception);
    } finally {
      notificationsBusy = false;
      notifyListeners();
    }
  }

  void clearBanner() {
    error = null;
    notice = null;
    notifyListeners();
  }

  Future<bool> saveProduct({
    String? productId,
    required String name,
    required String price,
    required String category,
    required String description,
    required bool isAvailable,
    String? imagePath,
  }) async {
    final saved = await _run<Product>(
      () => _repository.saveProduct(
        productId: productId,
        name: name,
        price: price,
        category: category,
        description: description,
        isAvailable: isAvailable,
        imagePath: imagePath,
      ),
    );

    if (saved == null) {
      return false;
    }

    final next = [...products];
    final index = next.indexWhere((item) => item.id == saved.id);

    if (index >= 0) {
      next[index] = saved;
      notice = 'Product updated.';
    } else {
      next.insert(0, saved);
      notice = 'Product added.';
    }

    products = next;
    notifyListeners();
    return true;
  }

  Future<bool> deleteProduct(String productId) async {
    final deleted = await _run<bool>(() async {
      await _repository.deleteProduct(productId);
      return true;
    });

    if (deleted != true) {
      return false;
    }

    products = products.where((item) => item.id != productId).toList(growable: false);
    notice = 'Product deleted.';
    notifyListeners();
    return true;
  }

  Future<bool> updateOrderStatus({
    required String orderId,
    required String status,
  }) async {
    final updated = await _run<Order>(
      () => _repository.updateOrderStatus(orderId: orderId, status: status),
    );

    if (updated == null) {
      return false;
    }

    _replaceOrder(updated);
    notice = 'Order ${statusLabel(status)}.';
    notifyListeners();
    return true;
  }

  Future<bool> sendOrderNotification({
    required String orderId,
    required String status,
    required String message,
  }) async {
    final result = await _run<String>(
      () => _repository.sendOrderNotification(
        orderId: orderId,
        status: status,
        message: message,
      ),
    );

    if (result == null) {
      return false;
    }

    notice = result;
    notifyListeners();
    return true;
  }

  Future<bool> updateProfile({
    required String name,
    required String ownerName,
    required String phone,
    required String whatsappNumber,
    required String address,
    required String description,
    required String deliveryCharge,
    required String upiId,
  }) async {
    final updated = await _run<Shop>(
      () => _repository.updateProfile(
        name: name,
        ownerName: ownerName,
        phone: phone,
        whatsappNumber: whatsappNumber,
        address: address,
        description: description,
        deliveryCharge: deliveryCharge,
        upiId: upiId,
      ),
    );

    if (updated == null) {
      return false;
    }

    shop = updated;
    _sessionController.updateShop(updated);
    notice = 'Shop profile saved.';
    notifyListeners();
    return true;
  }

  Future<bool> uploadLogo(String path) async {
    final updated = await _run<Shop>(() => _repository.uploadLogo(path));

    if (updated == null) {
      return false;
    }

    shop = updated;
    _sessionController.updateShop(updated);
    notice = 'Logo uploaded.';
    notifyListeners();
    return true;
  }

  Future<bool> uploadPaymentQr(String path) async {
    final updated = await _run<Shop>(() => _repository.uploadPaymentQr(path));

    if (updated == null) {
      return false;
    }

    shop = updated;
    _sessionController.updateShop(updated);
    notice = 'Payment QR uploaded.';
    notifyListeners();
    return true;
  }

  Future<bool> refreshQr(String baseUrl) async {
    final refreshed = await _run<QrInfo>(() => _repository.refreshQr(baseUrl));

    if (refreshed == null) {
      return false;
    }

    qrInfo = refreshed;
    qrBaseUrl = _extractBaseUrl(refreshed.qrUrl);

    if (shop != null) {
      final nextShop = shop!.copyWith(qrUrl: refreshed.qrUrl);
      shop = nextShop;
      _sessionController.updateShop(nextShop);
    }

    notice = 'QR refreshed with live shop link.';
    notifyListeners();
    return true;
  }

  String resolveAsset(String path) => _repository.resolveAssetUrl(path);

  @override
  void dispose() {
    _orderPollingTimer?.cancel();
    _tokenRefreshSubscription?.cancel();
    _foregroundMessageSubscription?.cancel();
    _messageOpenedSubscription?.cancel();
    super.dispose();
  }

  String _extractBaseUrl(String value) {
    final uri = Uri.tryParse(value);

    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      return '';
    }

    return '${uri.scheme}://${uri.authority}';
  }

  Future<T?> _run<T>(Future<T> Function() action) async {
    mutating = true;
    error = null;
    notifyListeners();

    try {
      return await action();
    } catch (exception) {
      error = _messageFrom(exception);
      return null;
    } finally {
      mutating = false;
      notifyListeners();
    }
  }

  String _messageFrom(Object exception) {
    if (exception is ApiException) {
      return exception.message;
    }

    return exception.toString().replaceFirst('Exception: ', '');
  }

  void _replaceOrder(Order order) {
    orders = orders
        .map((item) => item.id == order.id ? order : item)
        .toList(growable: false);
  }

  Future<void> _initializeNotifications() async {
    if (_notificationsInitialized) {
      return;
    }

    _notificationsInitialized = true;

    try {
      final ready = await ensureFirebaseInitialized();
      notificationsSupported = ready;

      if (!ready) {
        notificationStatus =
            'Firebase notifications are not configured for this app build yet.';
        return;
      }

      await ensureOwnerAlertsChannel();
      final messaging = FirebaseMessaging.instance;
      if (defaultTargetPlatform == TargetPlatform.android) {
        notificationPermissionGranted =
            await ensureAndroidNotificationPermission();
      } else {
        var settings = await messaging.getNotificationSettings();
        notificationPermissionGranted =
            settings.authorizationStatus == AuthorizationStatus.authorized ||
            settings.authorizationStatus == AuthorizationStatus.provisional;

        if (!notificationPermissionGranted) {
          settings = await messaging.requestPermission(
            alert: true,
            badge: true,
            sound: true,
          );
          notificationPermissionGranted =
              settings.authorizationStatus == AuthorizationStatus.authorized ||
              settings.authorizationStatus == AuthorizationStatus.provisional;
        }
      }

      if (notificationPermissionGranted) {
        final token = await messaging.getToken();
        if (token != null && token.isNotEmpty) {
          await _repository.registerDevice(
            fcmToken: token,
            platform: defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
          );
          backgroundNotificationsEnabled = true;
          notificationStatus = 'Background order notifications enabled on this device.';
        } else {
          notificationStatus = 'Notification permission is granted, but no device token is available yet.';
        }
      } else {
        notificationStatus = 'Notification permission not granted on this device.';
      }

      _tokenRefreshSubscription = messaging.onTokenRefresh.listen((token) {
        if (token.isEmpty) {
          return;
        }

        unawaited(_repository.registerDevice(
          fcmToken: token,
          platform: defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
        ));
        backgroundNotificationsEnabled = true;
        notificationStatus = 'Notification token synced for this device.';
        notifyListeners();
      });

      _foregroundMessageSubscription = FirebaseMessaging.onMessage.listen((message) {
        _handleRemoteMessage(message, fromTap: false);
      });

      _messageOpenedSubscription = FirebaseMessaging.onMessageOpenedApp.listen((message) {
        _handleRemoteMessage(message, fromTap: true);
      });

      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleRemoteMessage(initialMessage, fromTap: true);
      }
    } catch (exception) {
      notificationsSupported = false;
      notificationStatus = _messageFrom(exception);
    } finally {
      notifyListeners();
    }
  }

  void _ensureLiveAlerts() {
    if (_orderPollingTimer != null) {
      return;
    }

    liveAlertsConnected = true;
    _orderPollingTimer = Timer.periodic(
      const Duration(seconds: 8),
      (_) => unawaited(_pollOrders()),
    );
  }

  Future<void> _pollOrders() async {
    if (_pollingOrders || loading || shop == null) {
      return;
    }

    _pollingOrders = true;

    try {
      final latestOrders = await _repository.listOrders();
      _applyOrders(latestOrders, alertOnNew: true);
      liveAlertsConnected = true;
      error = null;
    } catch (exception) {
      liveAlertsConnected = false;
      error ??= _messageFrom(exception);
    } finally {
      _pollingOrders = false;
      notifyListeners();
    }
  }

  void _applyOrders(List<Order> latestOrders, {required bool alertOnNew}) {
    final newOrders = latestOrders
        .where((order) => !_knownOrderIds.contains(order.id))
        .toList(growable: false);

    orders = latestOrders;
    _knownOrderIds = latestOrders.map((order) => order.id).toSet();

    if (alertOnNew && newOrders.isNotEmpty) {
      _handleNewOrders(newOrders);
    }
  }

  void _handleNewOrders(List<Order> newOrders) {
    final latestOrder = newOrders.first;

    if (!_markAlertHandled(latestOrder.id)) {
      return;
    }

    final body = _buildOrderAlertBody(latestOrder);
    lastOrderAlertAt = DateTime.now();
    lastOrderAlertOrderNumber = latestOrder.orderNumber;
    notice = newOrders.length == 1
        ? body
        : '${newOrders.length} new orders received.';
    unawaited(showOwnerAlertNotification(
      title: newOrders.length == 1 ? 'New Order' : 'New Orders',
      body: newOrders.length == 1 ? body : '${newOrders.length} new orders received.',
      orderId: latestOrder.id,
    ));
    unawaited(_playOrderAlert());
  }

  Future<void> _playOrderAlert() async {
    try {
      await HapticFeedback.heavyImpact();
      if (defaultTargetPlatform != TargetPlatform.android) {
        await SystemSound.play(SystemSoundType.alert);
        await Future<void>.delayed(const Duration(milliseconds: 250));
        await SystemSound.play(SystemSoundType.alert);
      }
    } catch (_) {
      // Ignore platform alert sound failures and still keep the visual banner.
    }
  }

  void _handleRemoteMessage(RemoteMessage message, {required bool fromTap}) {
    final messageType = message.data['type']?.toString().toUpperCase() ?? '';
    final isNewOrder = messageType == 'NEW_ORDER';
    final orderId = message.data['orderId']?.toString() ?? '';
    final orderNumber = message.data['orderNumber']?.toString();
    final title = (message.notification?.title ?? '').trim().isNotEmpty
        ? message.notification!.title!.trim()
        : 'New Order';
    final body = message.notification?.body?.trim() ?? '';

    if (orderNumber?.isNotEmpty == true) {
      lastOrderAlertOrderNumber = orderNumber;
    }

    lastOrderAlertAt = DateTime.now();
    notice = body.isNotEmpty
        ? body
        : fromTap
            ? 'Order notification opened.'
            : 'New order notification received.';

    if (!fromTap &&
        isNewOrder &&
        _markAlertHandled(orderId.isNotEmpty ? orderId : (orderNumber ?? ''))) {
      unawaited(showOwnerAlertNotification(
        title: title,
        body: body.isNotEmpty ? body : 'New order notification received.',
        orderId: orderId,
      ));
      unawaited(_playOrderAlert());
    }

    unawaited(refreshOrders());
    notifyListeners();
  }

  String _buildOrderAlertBody(Order order) {
    final customerName = order.customer.name.isEmpty ? 'Customer' : order.customer.name;
    final itemSummary = order.items
        .take(3)
        .map((item) => '${item.quantity} x ${item.name}')
        .join(', ');

    final summary = itemSummary.isEmpty ? 'A new order was received.' : '$customerName: $itemSummary';
    return '$summary - ${formatCurrency(order.totalAmount)}';
  }

  bool _markAlertHandled(String value) {
    final key = value.trim();
    final now = DateTime.now();
    _recentAlertKeys.removeWhere(
      (_, timestamp) => now.difference(timestamp) > _alertDedupeWindow,
    );

    if (key.isEmpty) {
      return true;
    }

    if (_recentAlertKeys.containsKey(key)) {
      return false;
    }

    _recentAlertKeys[key] = now;
    return true;
  }
}
