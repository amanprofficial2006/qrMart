import '../../core/network/api_client.dart';
import '../../core/utils/json_utils.dart';
import '../../models/auth_response.dart';
import '../../models/google_auth_response.dart';
import '../../models/order.dart';
import '../../models/owner.dart';
import '../../models/owner_identity.dart';
import '../../models/product.dart';
import '../../models/qr_info.dart';
import '../../models/shop.dart';

class OwnerRepository {
  OwnerRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<AuthResponse> login({
    required String identifier,
    String password = '',
    String otp = '',
  }) async {
    final data = await _apiClient.post(
      '/api/v1/auth/login',
      body: {
        'identifier': identifier.trim(),
        if (password.trim().isNotEmpty) 'password': password,
        if (otp.trim().isNotEmpty) 'otp': otp.trim(),
      },
    );

    return AuthResponse.fromJson(mapFrom(data));
  }

  Future<AuthResponse> register({
    required String name,
    required String phone,
    required String email,
    String password = '',
    required String shopName,
    String address = '',
    List<MultipartFilePart> shopPhotos = const [],
  }) async {
    final cleanShopPhotos = shopPhotos
        .where((photo) => photo.path.trim().isNotEmpty)
        .map(
          (photo) => MultipartFilePart(
            field: photo.field,
            path: photo.path.trim(),
            filename: photo.filename?.trim(),
          ),
        )
        .toList(growable: false);

    final fields = <String, String>{
      'name': name.trim(),
      'phone': phone.trim(),
      'email': email.trim(),
      'shopName': shopName.trim(),
      'address': address.trim(),
      'registrationSource': 'owner_app',
      if (password.trim().isNotEmpty) 'password': password,
    };

    final data = cleanShopPhotos.isNotEmpty
        ? await _apiClient.multipart(
            'POST',
            '/api/v1/auth/register',
            fields: fields,
            files: cleanShopPhotos,
          )
        : await _apiClient.post(
            '/api/v1/auth/register',
            body: fields,
          );

    return AuthResponse.fromJson(mapFrom(data));
  }

  Future<GoogleAuthResponse> googleAuth({
    required String credential,
    String name = '',
    String phone = '',
    String password = '',
    String shopName = '',
  }) async {
    final data = await _apiClient.post(
      '/api/v1/auth/google',
      body: {
        'credential': credential.trim(),
        'name': name.trim(),
        'phone': phone.trim(),
        'password': password,
        'shopName': shopName.trim(),
      },
    );

    return GoogleAuthResponse.fromJson(mapFrom(data));
  }

  Future<OwnerIdentity> getIdentity() async {
    final data = await _apiClient.get('/api/v1/auth/me');
    final json = mapFrom(data);

    return OwnerIdentity(
      owner: Owner.fromJson(mapFrom(json['owner'])),
      shop: Shop.fromJson(mapFrom(json['shop'])),
    );
  }

  Future<List<Product>> listProducts() async {
    final data = await _apiClient.get('/api/v1/owner/products');
    return mapListFrom(data).map(Product.fromJson).toList(growable: false);
  }

  Future<List<Order>> listOrders() async {
    final data = await _apiClient.get('/api/v1/owner/orders');
    return mapListFrom(data).map(Order.fromJson).toList(growable: false);
  }

  Future<QrInfo> getQr() async {
    final data = await _apiClient.get('/api/v1/owner/qr');
    return QrInfo.fromJson(mapFrom(data));
  }

  Future<Shop> updateProfile({
    required String name,
    required String ownerName,
    required String phone,
    required String whatsappNumber,
    required String address,
    required String description,
    required String deliveryCharge,
    required String upiId,
  }) async {
    final data = await _apiClient.patch(
      '/api/v1/owner/profile',
      body: {
        'name': name.trim(),
        'ownerName': ownerName.trim(),
        'phone': phone.trim(),
        'whatsappNumber': whatsappNumber.trim(),
        'address': address.trim(),
        'description': description.trim(),
        'deliveryCharge':
            deliveryCharge.trim().isEmpty ? '0' : deliveryCharge.trim(),
        'upiId': upiId.trim(),
      },
    );

    return Shop.fromJson(mapFrom(data));
  }

  Future<Shop> uploadLogo(String filePath) async {
    final data = await _apiClient.multipart(
      'POST',
      '/api/v1/owner/profile/logo',
      files: [MultipartFilePart(field: 'logo', path: filePath)],
    );

    return Shop.fromJson(mapFrom(data));
  }

  Future<Shop> uploadPaymentQr(String filePath) async {
    final data = await _apiClient.multipart(
      'POST',
      '/api/v1/owner/profile/payment-qr',
      files: [MultipartFilePart(field: 'paymentQr', path: filePath)],
    );

    return Shop.fromJson(mapFrom(data));
  }

  Future<Product> saveProduct({
    String? productId,
    required String name,
    required String price,
    required String category,
    required String description,
    required bool isAvailable,
    String? imagePath,
  }) async {
    final fields = <String, String>{
      'name': name.trim(),
      'price': price.trim(),
      'category': category.trim().isEmpty ? 'General' : category.trim(),
      'description': description.trim(),
      'isAvailable': isAvailable.toString(),
    };

    final files = imagePath == null || imagePath.isEmpty
        ? const <MultipartFilePart>[]
        : [MultipartFilePart(field: 'image', path: imagePath)];

    final data = await _apiClient.multipart(
      productId == null ? 'POST' : 'PATCH',
      productId == null
          ? '/api/v1/owner/products'
          : '/api/v1/owner/products/$productId',
      fields: fields,
      files: files,
    );

    return Product.fromJson(mapFrom(data));
  }

  Future<void> deleteProduct(String productId) async {
    await _apiClient.delete('/api/v1/owner/products/$productId');
  }

  Future<Order> updateOrderStatus({
    required String orderId,
    required String status,
  }) async {
    final data = await _apiClient.patch(
      '/api/v1/owner/orders/$orderId/status',
      body: {'status': status},
    );

    return Order.fromJson(mapFrom(data));
  }

  Future<String> sendOrderNotification({
    required String orderId,
    required String message,
    required String status,
  }) async {
    final data = await _apiClient.post(
      '/api/v1/owner/send-notification',
      body: {
        'orderId': orderId,
        'message': message.trim(),
        'status': status,
      },
    );

    return stringFrom(mapFrom(data)['message'],
        fallback: 'Notification processed.');
  }

  Future<void> registerDevice({
    required String fcmToken,
    String platform = 'android',
  }) async {
    await _apiClient.post(
      '/api/v1/owner/devices',
      body: {
        'platform': platform,
        'fcmToken': fcmToken.trim(),
      },
    );
  }

  Future<QrInfo> refreshQr(String baseUrl) async {
    final data = await _apiClient.post(
      '/api/v1/owner/qr/refresh',
      body: {'baseUrl': baseUrl.trim()},
    );

    return QrInfo.fromJson(mapFrom(data));
  }

  String resolveAssetUrl(String path) => _apiClient.resolveUrl(path);

  void setToken(String? token) => _apiClient.setToken(token);
}
