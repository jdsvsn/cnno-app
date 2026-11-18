import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/format.dart';

enum ProductCategory {
  single('single', 'Single', 'Single rolls'),
  baby('baby', 'Baby Rolls', 'Baby Rolls'),
  duo('duo', 'Duo Box', 'Duo Box'),
  party('party', 'Party Box', 'Party Box');

  const ProductCategory(this.id, this.chipLabel, this.sectionTitle);
  final String id;
  final String chipLabel;
  final String sectionTitle;

  static ProductCategory fromId(String? id) =>
      values.firstWhere((c) => c.id == id, orElse: () => single);
}

class ProductVariant {
  const ProductVariant({required this.name, required this.price});
  final String name;
  final double price;

  Map<String, dynamic> toMap() => {'name': name, 'price': price};

  factory ProductVariant.fromMap(Map<String, dynamic> m) => ProductVariant(
        name: (m['name'] ?? '') as String,
        price: (m['price'] as num? ?? 0).toDouble(),
      );
}

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.variants,
    this.tagline = '',
    this.description = '',
    this.imageAsset,
    this.imageUrl,
    this.available = true,
    this.sortOrder = 0,
  });

  final String id;
  final String name;
  final ProductCategory category;
  final String tagline;
  final String description;

  /// Bundled client photo (for the seeded menu).
  final String? imageAsset;

  /// Cloud Storage photo uploaded by the admin.
  final String? imageUrl;
  final bool available;
  final List<ProductVariant> variants;
  final int sortOrder;

  bool get hasOptions => variants.length > 1;

  double get minPrice => variants.isEmpty
      ? 0
      : variants.map((v) => v.price).reduce((a, b) => a < b ? a : b);

  double get maxPrice => variants.isEmpty
      ? 0
      : variants.map((v) => v.price).reduce((a, b) => a > b ? a : b);

  /// "RM 8.00" or "From RM 14.00" (customer menu).
  String get priceLabel =>
      hasOptions && minPrice != maxPrice ? 'From ${rm(minPrice)}' : rm(minPrice);

  /// "RM 14 to 17" (admin list).
  String get priceRangeLabel => minPrice == maxPrice
      ? rm(minPrice)
      : 'RM ${minPrice.toStringAsFixed(0)} to ${maxPrice.toStringAsFixed(0)}';

  Product copyWith({bool? available}) => Product(
        id: id,
        name: name,
        category: category,
        variants: variants,
        tagline: tagline,
        description: description,
        imageAsset: imageAsset,
        imageUrl: imageUrl,
        available: available ?? this.available,
        sortOrder: sortOrder,
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'category': category.id,
        'tagline': tagline,
        'description': description,
        'imageAsset': imageAsset,
        'imageUrl': imageUrl,
        'available': available,
        'variants': variants.map((v) => v.toMap()).toList(),
        'sortOrder': sortOrder,
      };

  factory Product.fromMap(String id, Map<String, dynamic> m) => Product(
        id: id,
        name: (m['name'] ?? '') as String,
        category: ProductCategory.fromId(m['category'] as String?),
        tagline: (m['tagline'] ?? '') as String,
        description: (m['description'] ?? '') as String,
        imageAsset: m['imageAsset'] as String?,
        imageUrl: m['imageUrl'] as String?,
        available: (m['available'] ?? true) as bool,
        variants: ((m['variants'] as List?) ?? const [])
            .map((v) => ProductVariant.fromMap(Map<String, dynamic>.from(v as Map)))
            .toList(),
        sortOrder: (m['sortOrder'] as num? ?? 0).toInt(),
      );

  factory Product.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) =>
      Product.fromMap(d.id, d.data() ?? const {});
}
