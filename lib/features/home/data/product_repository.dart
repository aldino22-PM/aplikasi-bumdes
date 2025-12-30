import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart' as dio_pkg;
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_client.dart';
import '../../../core/config/app_config.dart';
import '../domain/product.dart';

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  final client = ref.read(apiClientProvider);
  return ProductRepository(client);
});

final productListProvider = FutureProvider<List<Product>>((ref) async {
  return ref.read(productRepositoryProvider).fetchProducts();
});

class ProductRepository {
  ProductRepository(this._api);

  final ApiClient _api;

  Future<List<Product>> fetchProducts() async {
    try {
      final response = await _api.client.get('/products.php');
      if (response.data is List) {
        final data = response.data as List;
        return data
            .map((e) => Product(
                  id: '${e['id']}',
                  title: e['title'] ?? 'Produk',
                  price: int.tryParse('${e['price']}') ?? 0,
                  image: _resolveImageUrl(
                      e['image'] ??
                          'https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=800&q=80'),
                  category: e['category'] ?? 'Lainnya',
                  rating: double.tryParse('${e['rating']}') ?? 4.5,
                  distance: e['distance'] ?? '1 km',
                  deliveryTime: e['delivery_time'] ?? '15-20 mnt',
                  weight: e['weight'] ?? '250 gr',
                  origin: e['origin'] ?? 'Kebun Mitra Baru',
                ))
            .toList();
      }
    } on DioException {
      // fallback ke mock jika API gagal
    }
    return _mockProducts;
  }

  Future<void> createProduct({
    required String title,
    required int price,
    required String category,
    String? imageUrl,
    XFile? imageFile,
    double rating = 4.8,
    String distance = '1 km',
    String deliveryTime = '10-15 mnt',
    String weight = '250 gr',
    String origin = 'Kebun Mitra Baru',
  }) async {
    final selectedImage = (imageUrl ?? '').trim();

    dio_pkg.MultipartFile? pickedImage;
    if (imageFile != null) {
      if (kIsWeb) {
        final bytes = await imageFile.readAsBytes();
        pickedImage = dio_pkg.MultipartFile.fromBytes(
          bytes,
          filename: imageFile.name,
        );
      } else {
        pickedImage = await dio_pkg.MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.name,
        );
      }
    }

    final formData = dio_pkg.FormData.fromMap({
      'title': title,
      'price': price,
      'category': category,
      'rating': rating,
      'distance': distance,
      'delivery_time': deliveryTime,
      'weight': weight,
      'origin': origin,
      if (selectedImage.isNotEmpty) 'image': selectedImage,
      if (pickedImage != null) 'image_file': pickedImage,
    });

    await _api.client.post('/add_product.php', data: formData);
  }

  Future<void> deleteProduct(String id) async {
    await _api.client.post('/delete_product.php', data: {'id': id});
  }

  String _resolveImageUrl(String raw) {
    final trimmed = raw.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    // treat as relative to API base URL
    return '${AppConfig.baseUrl}/$trimmed';
  }
}

final _mockProducts = <Product>[
  Product(
    id: '1',
    title: 'Pakcoy Hidroponik',
    price: 15000,
    image:
        'https://images.unsplash.com/photo-1528825871115-3581a5387919?auto=format&fit=crop&w=800&q=80',
    category: 'Pakcoy',
    distance: '0.6 km',
    deliveryTime: '12 mnt',
    weight: '250 gr',
    origin: 'Greenhouse Mitra Baru',
    rating: 4.8,
  ),
  Product(
    id: '2',
    title: 'Selada Keriting',
    price: 18000,
    image:
        'https://images.unsplash.com/photo-1461354464878-ad92f492a5a0?auto=format&fit=crop&w=800&q=80',
    category: 'Selada',
    distance: '0.3 km',
    deliveryTime: '8 mnt',
    weight: '200 gr',
    origin: 'Greenhouse Mitra Baru',
    rating: 4.7,
  ),
  Product(
    id: '3',
    title: 'Kangkung Hidro Fresh',
    price: 12000,
    image:
        'https://images.unsplash.com/photo-1501004318641-b39e6451bec6?auto=format&fit=crop&w=800&q=80',
    category: 'Kangkung',
    weight: '300 gr',
    origin: 'Greenhouse Mitra Baru',
    rating: 4.6,
  ),
  Product(
    id: '4',
    title: 'Bayam Organik',
    price: 14000,
    image:
        'https://images.unsplash.com/photo-1471194402529-8e0f5a675de6?auto=format&fit=crop&w=800&q=80',
    category: 'Bayam',
    distance: '1.2 km',
    deliveryTime: '16 mnt',
    weight: '250 gr',
    origin: 'Greenhouse Mitra Baru',
    rating: 4.8,
  ),
];
