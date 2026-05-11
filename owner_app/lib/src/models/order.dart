import '../core/utils/json_utils.dart';

class Order {
  const Order({
    required this.id,
    required this.orderNumber,
    required this.customer,
    required this.items,
    required this.pricing,
    required this.payment,
    required this.totalAmount,
    required this.status,
    required this.whatsappFallbackUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String orderNumber;
  final OrderCustomer customer;
  final List<OrderItem> items;
  final OrderPricing pricing;
  final OrderPayment payment;
  final double totalAmount;
  final String status;
  final String whatsappFallbackUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory Order.fromJson(Map<String, dynamic> json) {
    final notification = mapFrom(json['notification']);

    return Order(
      id: stringFrom(json['id'] ?? json['_id']),
      orderNumber: stringFrom(json['orderNumber']),
      customer: OrderCustomer.fromJson(mapFrom(json['customer'])),
      items: mapListFrom(json['items'])
          .map(OrderItem.fromJson)
          .toList(growable: false),
      pricing: OrderPricing.fromJson(mapFrom(json['pricing'])),
      payment: OrderPayment.fromJson(mapFrom(json['payment'])),
      totalAmount: doubleFrom(json['totalAmount']),
      status: stringFrom(json['status'], fallback: 'placed'),
      whatsappFallbackUrl: stringFrom(notification['whatsappFallbackUrl']),
      createdAt: dateTimeFrom(json['createdAt']),
      updatedAt: dateTimeFrom(json['updatedAt']),
    );
  }
}

class OrderCustomer {
  const OrderCustomer({
    required this.name,
    required this.phone,
    required this.address,
    required this.note,
    required this.mapsUrl,
  });

  final String name;
  final String phone;
  final String address;
  final String note;
  final String mapsUrl;

  factory OrderCustomer.fromJson(Map<String, dynamic> json) {
    final location = mapFrom(json['location']);

    return OrderCustomer(
      name: stringFrom(json['name']),
      phone: stringFrom(json['phone']),
      address: stringFrom(json['address']),
      note: stringFrom(json['note']),
      mapsUrl: stringFrom(location['mapsUrl']),
    );
  }
}

class OrderItem {
  const OrderItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
    required this.subtotal,
  });

  final String productId;
  final String name;
  final double price;
  final int quantity;
  final double subtotal;

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: stringFrom(json['productId']),
      name: stringFrom(json['name']),
      price: doubleFrom(json['price']),
      quantity: doubleFrom(json['quantity']).toInt(),
      subtotal: doubleFrom(json['subtotal']),
    );
  }
}

class OrderPricing {
  const OrderPricing({
    required this.itemTotal,
    required this.deliveryCharge,
    required this.finalTotal,
  });

  final double itemTotal;
  final double deliveryCharge;
  final double finalTotal;

  factory OrderPricing.fromJson(Map<String, dynamic> json) {
    return OrderPricing(
      itemTotal: doubleFrom(json['itemTotal']),
      deliveryCharge: doubleFrom(json['deliveryCharge']),
      finalTotal: doubleFrom(json['finalTotal']),
    );
  }
}

class OrderPayment {
  const OrderPayment({
    required this.method,
    required this.declaredPaid,
    required this.upiId,
  });

  final String method;
  final bool declaredPaid;
  final String upiId;

  factory OrderPayment.fromJson(Map<String, dynamic> json) {
    return OrderPayment(
      method: stringFrom(json['method'], fallback: 'unknown'),
      declaredPaid: boolFrom(json['declaredPaid']),
      upiId: stringFrom(json['upiId']),
    );
  }
}

