import '../core/utils/json_utils.dart';

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.category,
    required this.isAvailable,
    required this.sortOrder,
  });

  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String category;
  final bool isAvailable;
  final int sortOrder;

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: stringFrom(json['id'] ?? json['_id']),
      name: stringFrom(json['name']),
      description: stringFrom(json['description']),
      price: doubleFrom(json['price']),
      imageUrl: stringFrom(json['imageUrl']),
      category: stringFrom(json['category'], fallback: 'General'),
      isAvailable: boolFrom(json['isAvailable'], fallback: true),
      sortOrder: doubleFrom(json['sortOrder']).toInt(),
    );
  }
}

