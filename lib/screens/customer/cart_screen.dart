import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/product.dart';
import '../../services/product_repository.dart';
import '../../state/cart.dart';
import '../../theme.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';
import 'checkout_screen.dart';
import 'customer_shell.dart';

/// UI-04 Cart (FR-05).
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late final Stream<List<Product>> _products = context.read<ProductRepository>().watchAll();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cart = context.watch<Cart>();
    return StreamBuilder<List<Product>>(
      stream: _products,
      builder: (context, snap) {
        final unavailable = snap.hasData ? cart.unavailableItems(snap.data!) : const [];
        final blockedKeys = unavailable.map((i) => i.key).toSet();
        return CnnoPage(
          title: 'Your cart',
          bottom: cart.isEmpty
              ? null
              : FilledButton(
                  onPressed: blockedKeys.isEmpty && snap.hasData
                      ? () => Navigator.of(context)
                          .push(MaterialPageRoute(builder: (_) => const CheckoutScreen()))
                      : null,
                  child: const Text('Proceed to checkout'),
                ),
          child: cart.isEmpty
              ? EmptyState(
                  icon: Icons.shopping_bag_outlined,
                  message: 'Your cart is empty.',
                  action: OutlinedButton(
                    style: OutlinedButton.styleFrom(minimumSize: const Size(180, 48)),
                    onPressed: () => CustomerShell.goToTab(context, CustomerShell.menu),
                    child: const Text('Browse the menu'),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                  children: [
                    for (final item in cart.items)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: CnnoCard(
                          child: Row(
                            children: [
                              ProductImage(asset: item.imageAsset, url: item.imageUrl, size: 56),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.displayName,
                                        style: t.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                                    Text('${rm(item.unitPrice)} each',
                                        style: t.bodySmall?.copyWith(color: CnnoColors.muted)),
                                    if (blockedKeys.contains(item.key))
                                      Text('No longer available. Remove to continue.',
                                          style: t.bodySmall?.copyWith(color: CnnoColors.primary)),
                                  ],
                                ),
                              ),
                              QuantityStepper(
                                value: item.quantity,
                                onChanged: (v) => cart.setQuantity(item.key, v),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 4),
                    CnnoCard(
                      child: Column(
                        children: [
                          _row(t, 'Subtotal', rm(cart.subtotal)),
                          const SizedBox(height: 6),
                          _row(t, 'Delivery', 'Booked by CNNO on Grab, quoted separately'),
                        ],
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  static Widget _row(TextTheme t, String a, String b) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(a, style: t.bodyMedium?.copyWith(color: CnnoColors.muted)),
          const SizedBox(width: 24),
          Expanded(child: Text(b, textAlign: TextAlign.right, style: t.bodyMedium)),
        ],
      );
}
