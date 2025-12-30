import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../data/product_repository.dart';
import '../domain/product.dart';

class ProductListAdminPage extends ConsumerWidget {
  const ProductListAdminPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productListProvider);
    return SafeArea(
      child: products.when(
        data: (items) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(productListProvider);
          },
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemBuilder: (_, index) {
              final Product p = items[index];
              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          width: 72,
                          height: 72,
                          child: p.image.isNotEmpty
                              ? Image.network(p.image, fit: BoxFit.cover)
                              : Container(
                                  color: Colors.grey.shade200,
                                  child: const Icon(Icons.image_not_supported),
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${p.category} · ${_formatCurrency(p.price)}',
                              style: const TextStyle(color: Colors.black54),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${p.weight} · Estimasi ${p.deliveryTime} · Jarak ${p.distance}',
                              style: const TextStyle(
                                  color: Colors.black54, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDelete(context, ref, p.id),
                      ),
                    ],
                  ),
                ),
              );
            },
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemCount: items.length,
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Gagal memuat produk: $e')),
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, String productId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus produk?'),
        content: const Text('Produk akan dihapus dari database.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          )
        ],
      ),
    );
    if (ok == true) {
      try {
        await ref.read(productRepositoryProvider).deleteProduct(productId);
        ref.invalidate(productListProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Produk dihapus')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal hapus: $e')),
          );
        }
      }
    }
  }
}

String _formatCurrency(int value) {
  final digits = value.toString().split('');
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    buffer.write(digits[i]);
    final fromEnd = digits.length - i - 1;
    if (fromEnd > 0 && fromEnd % 3 == 0) {
      buffer.write('.');
    }
  }
  return 'Rp ${buffer.toString()}';
}
