import 'product.dart';

class CartItem {
  CartItem({
    required this.productId,
    required this.productName,
    required this.variantName,
    required this.unitPrice,
    required this.quantity,
    this.imageAsset,
    this.imageUrl,
    this.hasOptions = false,
  });

  factory CartItem.fromProduct(Product p, ProductVariant v, int qty) => CartItem(
        productId: p.id,
        productName: p.name,
        variantName: v.name,
        unitPrice: v.price,
        quantity: qty,
        imageAsset: p.imageAsset,
        imageUrl: p.imageUrl,
        hasOptions: p.hasOptions,
      );

  final String productId;
  final String productName;
  final String variantName;
  final double unitPrice;
  int quantity;
  final String? imageAsset;
  final String? imageUrl;
  final bool hasOptions;

  String get key => '$productId|$variantName';

  /// "Duo Box (OG + Pista)" for boxes, "OG Cinnamon Roll" for single rolls.
  String get displayName =>
      hasOptions ? '$productName ($variantName)' : productName;

  double get lineTotal => unitPrice * quantity;

  Map<String, dynamic> toOrderMap() => {
        'productId': productId,
        'name': displayName,
        'unitPrice': unitPrice,
        'quantity': quantity,
        'lineTotal': lineTotal,
      };
}
