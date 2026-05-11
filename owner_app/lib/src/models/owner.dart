import '../core/utils/json_utils.dart';

class Owner {
  const Owner({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.shopId,
  });

  final String id;
  final String name;
  final String phone;
  final String email;
  final String shopId;

  factory Owner.fromJson(Map<String, dynamic> json) {
    return Owner(
      id: stringFrom(json['id'] ?? json['_id']),
      name: stringFrom(json['name']),
      phone: stringFrom(json['phone']),
      email: stringFrom(json['email']),
      shopId: stringFrom(json['shopId']),
    );
  }
}

