import '../core/utils/json_utils.dart';
import 'owner.dart';
import 'shop.dart';

class AuthResponse {
  const AuthResponse({
    required this.token,
    required this.owner,
    required this.shop,
  });

  final String token;
  final Owner owner;
  final Shop shop;

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: stringFrom(json['token']),
      owner: Owner.fromJson(mapFrom(json['owner'])),
      shop: Shop.fromJson(mapFrom(json['shop'])),
    );
  }
}
