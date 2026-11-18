import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/product.dart';
import '../../services/ai_service.dart';
import '../../services/order_repository.dart';
import '../../services/product_repository.dart';
import '../../state/cart.dart';
import '../../state/session.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'product_detail_screen.dart';

/// UI-02 Menu with AI recommendation (FR-03, FR-04, FR-AI-01).
class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  late final Stream<List<Product>> _products = context.read<ProductRepository>().watchAll();
  ProductCategory _category = ProductCategory.single;
  Future<Recommendation?>? _recommendation;
  int _lastProductsHash = 0;

  void _loadRecommendation(List<Product> products) {
    final hash = Object.hashAll(products.map((p) => '${p.id}${p.available}'));
    if (hash == _lastProductsHash && _recommendation != null) return;
    _lastProductsHash = hash;
    final user = context.read<Session>().user!;
    final orders = context.read<OrderRepository>();
    final ai = context.read<AiService>();
    _recommendation = orders.watchMyOrders(user.uid).first.then((past) {
      final ids = past.expand((o) => o.items.map((i) => i.productId)).toList();
      return ai.recommend(
        products: products,
        favourites: user.favouriteFlavours,
        pastOrderedProductIds: ids,
      );
    }).catchError((_) => AiService.fallbackRecommendation(
        products.where((p) => p.available).toList(), user.favouriteFlavours, const []));
  }

  void _open(Product p) => Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => ProductDetailScreen(product: p)));

  void _quickAdd(Product p) {
    if (p.hasOptions) return _open(p);
    if (context.read<Cart>().add(p, p.variants.first)) {
      showMessage(context, '${p.name} added to cart');
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final user = context.watch<Session>().user!;
    return Scaffold(
      body: Column(
        children: [
          const Awning(),
          Expanded(
            child: StreamBuilder<List<Product>>(
              stream: _products,
              builder: (context, snap) {
                if (snap.hasError) {
                  return const EmptyState(
                      icon: Icons.wifi_off, message: 'Could not load the menu. Check your connection.');
                }
                if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                final products = snap.data!;
                if (products.isEmpty) {
                  return const EmptyState(
                      icon: Icons.bakery_dining, message: 'The menu is not available yet.');
                }
                _loadRecommendation(products);
                final shown = products.where((p) => p.category == _category).toList();
                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  children: [
                    Text('Hello, ${user.firstName}',
                        style: t.bodyMedium?.copyWith(color: CnnoColors.muted)),
                    const SizedBox(height: 2),
                    Text('What are you craving today?',
                        style: t.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 14),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final c in ProductCategory.values)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(c.chipLabel),
                                selected: c == _category,
                                labelStyle: TextStyle(
                                    color: c == _category ? Colors.white : CnnoColors.text,
                                    fontWeight: FontWeight.w600),
                                onSelected: (_) => setState(() => _category = c),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _RecommendationCard(future: _recommendation, onOpen: _open),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: Text(_category.sectionTitle,
                              style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                        ),
                        Text('Pre-order available',
                            style: t.bodySmall?.copyWith(color: CnnoColors.available)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (shown.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text('Nothing here yet.',
                            textAlign: TextAlign.center,
                            style: t.bodyMedium?.copyWith(color: CnnoColors.muted)),
                      ),
                    for (final p in shown)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _ProductRow(product: p, onTap: () => _open(p), onAdd: () => _quickAdd(p)),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({required this.future, required this.onOpen});
  final Future<Recommendation?>? future;
  final ValueChanged<Product> onOpen;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return FutureBuilder<Recommendation?>(
      future: future,
      builder: (context, snap) {
        final r = snap.data;
        if (snap.connectionState != ConnectionState.done) {
          return Container(
            height: 110,
            decoration: BoxDecoration(color: CnnoColors.maroon, borderRadius: BorderRadius.circular(18)),
            alignment: Alignment.center,
            child: const SizedBox(
                width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
          );
        }
        if (r == null) return const SizedBox.shrink();
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
          decoration: BoxDecoration(color: CnnoColors.maroon, borderRadius: BorderRadius.circular(18)),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.fromAi ? 'AI Smart Recommendation' : 'Recommended for you',
                        style: t.labelSmall?.copyWith(color: const Color(0xFFF3C9D1))),
                    const SizedBox(height: 4),
                    Text(r.message,
                        style: t.titleSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 34),
                        backgroundColor: CnnoColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        textStyle: t.labelMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      onPressed: () => onOpen(r.product),
                      child: const Text('View flavour'),
                    ),
                  ],
                ),
              ),
              ProductImage.of(r.product, size: 92),
            ],
          ),
        );
      },
    );
  }
}

class _ProductRow extends StatelessWidget {
  const _ProductRow({required this.product, required this.onTap, required this.onAdd});
  final Product product;
  final VoidCallback onTap;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return CnnoCard(
      onTap: onTap,
      child: Row(
        children: [
          ProductImage.of(product, size: 64),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name, style: t.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                AvailabilityText(available: product.available),
                const SizedBox(height: 2),
                Text(product.priceLabel,
                    style: t.bodyMedium?.copyWith(color: CnnoColors.primary, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          IconButton.filled(
            tooltip: product.available ? 'Add ${product.name}' : '${product.name} is sold out',
            onPressed: product.available ? onAdd : null,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}
