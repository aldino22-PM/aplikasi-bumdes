import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/cart_item.dart';
import '../domain/order.dart';
import '../domain/sales_summary.dart';

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  final api = ref.read(apiClientProvider);
  return OrderRepository(api);
});

class OrderRepository {
  OrderRepository(this._api);

  final ApiClient _api;

  Future<List<OrderSummary>> fetchOrders() async {
    final response = await _api.client.get('/orders.php');
    final data = response.data;
    if (data is! List) return const [];
    return data.map<OrderSummary>((raw) {
      final statusString = (raw['status'] ?? 'pending').toString();
      final statusLower = statusString.toLowerCase();
      final status = statusLower == 'delivered'
          ? OrderStatus.delivered
          : (statusLower == 'verified' || statusLower == 'accepted')
              ? OrderStatus.verified
              : statusLower == 'on_the_way'
                  ? OrderStatus.packing
                  : statusLower == 'cancelled'
                      ? OrderStatus.cancelled
                      : OrderStatus.pending;
      final total = int.tryParse('${raw['total'] ?? 0}') ?? 0;
      final createdAt = (raw['created_at'] ?? '').toString();
      return OrderSummary(
        id: '${raw['id']}',
        customer: (raw['customer'] ?? 'Pelanggan').toString(),
        itemsDescription: (raw['items_description'] ?? '-').toString(),
        total: total,
        contact: (raw['contact'] ?? '').toString(),
        createdAt: createdAt,
        status: status,
      );
    }).toList();
  }

  Future<void> verifyOrder(String orderId) async {
    await _api.client.post('/verify_order.php', data: {
      'order_id': orderId,
      'status': 'accepted',
    });
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    await _api.client.post('/verify_order.php', data: {
      'order_id': orderId,
      'status': status,
    });
  }

  Future<int> createOrder(
    List<CartItem> items,
    int total, {
    String? userId,
  }) async {
    final payload = {
      'total': total,
      if (userId != null && userId.isNotEmpty) 'user_id': userId,
      'items': items
          .map((item) => {
                'product_id': item.product.id,
                'quantity': item.quantity,
                'price': item.product.price,
              })
          .toList(),
    };

    final response = await _api.client.post(
      '/create_order.php',
      data: payload,
      options: Options(
        headers: {'Content-Type': 'application/json'},
      ),
    );
    final data = response.data;
    if (data is Map && data['order_id'] != null) {
      return int.tryParse('${data['order_id']}') ?? 0;
    }
    return 0;
  }

  Future<SalesSummary> fetchSalesSummary(String range) async {
    final response = await _api.client.get('/sales_summary.php', queryParameters: {
      'range': range,
    });
    final data = response.data;
    if (data is! Map) {
      return const SalesSummary(totalRevenue: 0, ordersCount: 0, orders: []);
    }
    final ordersRaw = data['orders'];
    final orders = ordersRaw is List
        ? ordersRaw.map<OrderSummary>((raw) {
            final statusLower = (raw['status'] ?? 'pending').toString().toLowerCase();
            final status = statusLower == 'delivered'
                ? OrderStatus.delivered
                : (statusLower == 'verified' || statusLower == 'accepted')
                    ? OrderStatus.verified
                    : statusLower == 'on_the_way'
                        ? OrderStatus.packing
                        : statusLower == 'cancelled'
                            ? OrderStatus.cancelled
                            : OrderStatus.pending;
            final total = int.tryParse('${raw['total'] ?? 0}') ?? 0;
            return OrderSummary(
              id: '${raw['id']}',
              customer: (raw['customer'] ?? 'Pelanggan').toString(),
              itemsDescription: (raw['items_description'] ?? '-').toString(),
              total: total,
              contact: (raw['contact'] ?? '').toString(),
              createdAt: (raw['created_at'] ?? '').toString(),
              status: status,
            );
          }).toList()
        : <OrderSummary>[];
    final totalRevenue = int.tryParse('${data['total_revenue'] ?? 0}') ?? 0;
    final count = int.tryParse('${data['orders_count'] ?? 0}') ?? 0;
    return SalesSummary(
      totalRevenue: totalRevenue,
      ordersCount: count,
      orders: orders,
    );
  }
}
