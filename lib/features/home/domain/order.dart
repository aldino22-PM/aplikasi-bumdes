enum OrderStatus { pending, packing, verified, delivered, cancelled }

class OrderSummary {
  const OrderSummary({
    required this.id,
    required this.customer,
    required this.itemsDescription,
    required this.total,
    required this.contact,
    required this.createdAt,
    required this.status,
  });

  final String id;
  final String customer;
  final String itemsDescription;
  final int total;
  final String contact;
  final String createdAt;
  final OrderStatus status;

  OrderSummary copyWith({OrderStatus? status}) {
    return OrderSummary(
      id: id,
      customer: customer,
      itemsDescription: itemsDescription,
      total: total,
      contact: contact,
      createdAt: createdAt,
      status: status ?? this.status,
    );
  }
}
