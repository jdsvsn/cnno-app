import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/product.dart';
import '../../services/product_repository.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'product_edit_screen.dart';

/// UI-09 Admin products (FR-11 manage products, prices and availability).
class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  late final Stream<List<Product>> _stream = context.read<ProductRepository>().watchAll();

  void _edit(Product? p) => Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => ProductEditScreen(product: p)));

  Future<void> _delete(Product p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Delete ${p.name}?'),
        content: const Text('Customers will no longer see this product.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await context.read<ProductRepository>().delete(p.id);
      if (mounted) showMessage(context, '${p.name} deleted');
    } catch (_) {
      if (mounted) showMessage(context, 'Could not delete the product');
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final repo = context.read<ProductRepository>();
    return CnnoPage(
      title: 'Products',
      bottom: FilledButton(onPressed: () => _edit(null), child: const Text('+ Add new product')),
      child: StreamBuilder<List<Product>>(
        stream: _stream,
        builder: (context, snap) {
          if (snap.hasError) return const EmptyState(icon: Icons.lock_outline, message: 'Could not load products.');
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final products = snap.data!;
          if (products.isEmpty) {
            return const EmptyState(
                icon: Icons.bakery_dining,
                message: 'No products yet. Add one, or load the CNNO menu from Settings.');
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            children: [
              for (final p in products)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: CnnoCard(
                    child: Row(
                      children: [
                        ProductImage.of(p, size: 60),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(p.name, style: t.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                            Text(p.priceRangeLabel,
                                style: t.bodyMedium?.copyWith(color: CnnoColors.primary, fontWeight: FontWeight.w700)),
                            Row(children: [
                              _link('Edit', () => _edit(p)),
                              Text(' | ', style: t.bodySmall?.copyWith(color: CnnoColors.muted)),
                              _link('Delete', () => _delete(p)),
                            ]),
                          ]),
                        ),
                        Column(children: [
                          Switch(
                            value: p.available,
                            activeTrackColor: CnnoColors.available,
                            onChanged: (v) => repo.setAvailable(p.id, v).catchError(
                                (_) {
                                  if (context.mounted) showMessage(context, 'Could not update availability');
                                }),
                          ),
                          Text(p.available ? 'In stock' : 'Sold out',
                              style: t.labelSmall?.copyWith(color: CnnoColors.muted)),
                        ]),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _link(String text, VoidCallback onTap) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(text, style: const TextStyle(fontSize: 12, color: CnnoColors.muted)),
        ),
      );
}
