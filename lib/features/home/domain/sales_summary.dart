import 'order.dart';

class SalesSummary {
  const SalesSummary({
    required this.totalRevenue,
    required this.ordersCount,
    required this.orders,
  });

  final int totalRevenue;
  final int ordersCount;
  final List<OrderSummary> orders;
}
