import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../domain/product.dart';
import 'cart_controller.dart';

class ProductDetailPage extends ConsumerStatefulWidget {
  const ProductDetailPage({super.key, required this.product});

  final Product product;

  static const routeName = '/product/:id';

  @override
  ConsumerState<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends ConsumerState<ProductDetailPage> {
  int qty = 1;

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final subtotal = product.price * qty;
    return Scaffold(
      backgroundColor: const Color(0xFFF5FFF8),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Stack(
                children: [
                  Hero(
                    tag: 'product-${product.id}',
                    child: AspectRatio(
                      aspectRatio: 16 / 10,
                      child: Image.network(
                        product.image,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: CircleAvatar(
                      backgroundColor: Colors.white,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => context.pop(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SliverToBoxAdapter(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 20,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.star,
                                        color: Colors.amber, size: 18),
                                    const SizedBox(width: 4),
                                    Text(product.rating.toString()),
                                    const SizedBox(width: 8),
                                    Text(
                                      product.distance,
                                      style: const TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('Harga',
                                  style: TextStyle(color: Colors.grey)),
                              Text(
                                'Rp${product.price}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 22,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _Chip(text: product.category),
                          const SizedBox(width: 8),
                          _Chip(text: product.deliveryTime),
                          const SizedBox(width: 8),
                          _Chip(text: product.weight),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Sayur hidroponik segar, dipetik pagi hari tanpa pestisida. Simpan di kulkas untuk menjaga kerenyahan.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5FFF8),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.local_shipping_outlined),
                            const SizedBox(width: 8),
                            Text(
                              '${product.deliveryTime} • ${product.distance}',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const Spacer(),
                            Row(
                              children: [
                                _QtyButton(
                                  icon: Icons.remove,
                                  onTap:
                                      qty > 1 ? () => setState(() => qty--) : null,
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 10),
                                  child: Text(
                                    qty.toString(),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700),
                                  ),
                                ),
                                _QtyButton(
                                  icon: Icons.add,
                                  onTap: () => setState(() => qty++),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAFDFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE0F2E9)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Ringkasan Pesanan',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 14),
                            ),
                            const SizedBox(height: 8),
                            _RowPrice(
                                label: '${qty} x ${product.title}',
                                value: 'Rp${product.price * qty}'),
                            _RowPrice(
                                label: 'Pengantaran',
                                value: 'Rp0',
                                labelColor: Colors.grey),
                            const Divider(),
                            _RowPrice(
                              label: 'Total',
                              value: 'Rp$subtotal',
                              bold: true,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, -4),
            )
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Total',
                      style: TextStyle(color: Colors.grey, fontSize: 12)),
                  Text(
                    'Rp$subtotal',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  for (int i = 0; i < qty; i++) {
                    ref.read(cartProvider.notifier).add(product);
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$qty x ${product.title} ditambahkan'),
                    ),
                  );
                  context.pop();
                },
                child: const Text('Tambah ke Keranjang'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE8FFF2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({required this.icon, this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6F2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18),
      ),
    );
  }
}

class _RowPrice extends StatelessWidget {
  const _RowPrice(
      {required this.label, required this.value, this.bold = false, this.labelColor});

  final String label;
  final String value;
  final bool bold;
  final Color? labelColor;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
      color: labelColor ?? Colors.black87,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(value, style: style),
        ],
      ),
    );
  }
}
