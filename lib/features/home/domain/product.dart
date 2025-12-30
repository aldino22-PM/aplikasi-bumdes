class Product {
  Product({
    required this.id,
    required this.title,
    required this.price,
    required this.image,
    required this.category,
    this.rating = 4.8,
    this.distance = '0.8 km',
    this.deliveryTime = '10-15 mnt',
    this.weight = '250 gr',
    this.origin = 'Kebun Mitra Baru',
  });

  final String id;
  final String title;
  final int price;
  final String image;
  final String category;
  final double rating;
  final String distance;
  final String deliveryTime;
  final String weight;
  final String origin;
}
