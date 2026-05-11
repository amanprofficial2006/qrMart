import '../core/utils/json_utils.dart';

class Shop {
  const Shop({
    required this.id,
    required this.name,
    required this.slug,
    required this.ownerName,
    required this.logoUrl,
    required this.phone,
    required this.whatsappNumber,
    required this.address,
    required this.description,
    required this.upiId,
    required this.paymentQrCodeUrl,
    required this.deliveryCharge,
    required this.qrUrl,
    required this.isActive,
  });

  final String id;
  final String name;
  final String slug;
  final String ownerName;
  final String logoUrl;
  final String phone;
  final String whatsappNumber;
  final String address;
  final String description;
  final String upiId;
  final String paymentQrCodeUrl;
  final double deliveryCharge;
  final String qrUrl;
  final bool isActive;

  factory Shop.fromJson(Map<String, dynamic> json) {
    final payment = mapFrom(json['payment']);
    final settings = mapFrom(json['settings']);

    return Shop(
      id: stringFrom(json['id'] ?? json['_id']),
      name: stringFrom(json['name']),
      slug: stringFrom(json['slug']),
      ownerName: stringFrom(json['ownerName']),
      logoUrl: stringFrom(json['logoUrl']),
      phone: stringFrom(json['phone']),
      whatsappNumber: stringFrom(json['whatsappNumber']),
      address: stringFrom(json['address']),
      description: stringFrom(json['description']),
      upiId: stringFrom(payment['upiId']),
      paymentQrCodeUrl: stringFrom(payment['qrCodeUrl']),
      deliveryCharge: doubleFrom(settings['deliveryCharge']),
      qrUrl: stringFrom(json['qrUrl']),
      isActive: boolFrom(json['isActive'], fallback: true),
    );
  }

  Shop copyWith({
    String? id,
    String? name,
    String? slug,
    String? ownerName,
    String? logoUrl,
    String? phone,
    String? whatsappNumber,
    String? address,
    String? description,
    String? upiId,
    String? paymentQrCodeUrl,
    double? deliveryCharge,
    String? qrUrl,
    bool? isActive,
  }) {
    return Shop(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      ownerName: ownerName ?? this.ownerName,
      logoUrl: logoUrl ?? this.logoUrl,
      phone: phone ?? this.phone,
      whatsappNumber: whatsappNumber ?? this.whatsappNumber,
      address: address ?? this.address,
      description: description ?? this.description,
      upiId: upiId ?? this.upiId,
      paymentQrCodeUrl: paymentQrCodeUrl ?? this.paymentQrCodeUrl,
      deliveryCharge: deliveryCharge ?? this.deliveryCharge,
      qrUrl: qrUrl ?? this.qrUrl,
      isActive: isActive ?? this.isActive,
    );
  }
}

