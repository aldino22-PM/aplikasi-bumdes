import 'product.dart';

class CartItem {
  CartItem({required this.product, required this.quantity});

  final Product product;
  final int quantity;

  CartItem copyWith({int? quantity}) =>
      CartItem(product: product, quantity: quantity ?? this.quantity);

  int get total => product.price * quantity;
}
