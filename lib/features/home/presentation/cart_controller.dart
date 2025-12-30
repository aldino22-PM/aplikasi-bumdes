import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/cart_item.dart';
import '../domain/product.dart';

final cartProvider =
    StateNotifierProvider<CartController, List<CartItem>>((ref) {
  return CartController();
});

final cartTotalProvider = Provider<int>((ref) {
  final items = ref.watch(cartProvider);
  return items.fold(0, (sum, item) => sum + item.total);
});

class CartController extends StateNotifier<List<CartItem>> {
  CartController() : super(const []);

  void add(Product product) {
    final index = state.indexWhere((c) => c.product.id == product.id);
    if (index >= 0) {
      final updated = [...state];
      final current = updated[index];
      updated[index] = current.copyWith(quantity: current.quantity + 1);
      state = updated;
    } else {
      state = [...state, CartItem(product: product, quantity: 1)];
    }
  }

  void updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      state = state.where((c) => c.product.id != productId).toList();
      return;
    }
    final index = state.indexWhere((c) => c.product.id == productId);
    if (index >= 0) {
      final updated = [...state];
      updated[index] = updated[index].copyWith(quantity: quantity);
      state = updated;
    }
  }

  void clear() => state = const [];
}
