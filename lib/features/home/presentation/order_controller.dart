import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/order_repository.dart';
import '../domain/order.dart';

final orderListProvider =
    StateNotifierProvider<OrderListController, AsyncValue<List<OrderSummary>>>(
        (ref) {
  final repo = ref.read(orderRepositoryProvider);
  return OrderListController(repo);
});

class OrderListController
    extends StateNotifier<AsyncValue<List<OrderSummary>>> {
  OrderListController(this._repo) : super(const AsyncValue.loading()) {
    load();
  }

  final OrderRepository _repo;

  Future<void> load() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.fetchOrders());
  }

  Future<void> verify(String orderId) async {
    await _repo.verifyOrder(orderId);
    await load();
  }

  Future<void> markDelivered(String orderId) async {
    await _repo.updateOrderStatus(orderId, 'delivered');
    await load();
  }

  Future<void> markPacking(String orderId) async {
    await _repo.updateOrderStatus(orderId, 'on_the_way');
    await load();
  }

  Future<void> reject(String orderId) async {
    await _repo.updateOrderStatus(orderId, 'cancelled');
    await load();
  }

  void addFromCheckout(OrderSummary summary) {
    state.whenData((data) {
      state = AsyncValue.data([summary, ...data]);
    });
  }
}
