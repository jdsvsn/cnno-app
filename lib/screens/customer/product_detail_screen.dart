import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/product.dart';
import '../../state/cart.dart';
import '../../theme.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';

/// UI-03 Product detail (FR-03, FR-04, FR-05).
class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key, required this.product});
  final Product product;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late ProductVariant _variant = widget.product.variants.first;
  int _qty = 1;

  void _add() {
    final p = widget.product;
    if (context.read<Cart>().add(p, _variant, quantity: _qty)) {
      showMessage(context, '${p.hasOptions ? '${p.name} (${_variant.name})' : p.name} added to cart');
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final p = widget.product;
    final shortName = p.name.replaceAll(' Roll', '');
    return CnnoPage(
      title: p.name,
      showBack: true,
      bottom: Row(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total', style: t.bodySmall?.copyWith(color: CnnoColors.muted)),
              Text(rm(_variant.price * _qty),
                  style: t.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: FilledButton(
              onPressed: p.available ? _add : null,
              child: Text(p.available ? 'Add to cart' : 'Sold out'),
            ),
          ),
        ],
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        children: [
          Container(
            height: 260,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
            alignment: Alignment.center,
            child: ProductImage.of(p, size: 230),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Text(p.category == ProductCategory.single ? shortName : p.name,
                    style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
              ),
              Text(rm(_variant.price),
                  style: t.titleLarge?.copyWith(color: CnnoColors.primary, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          Align(alignment: Alignment.centerLeft, child: AvailabilityText(available: p.available, pill: true)),
          const SizedBox(height: 12),
          if (p.tagline.isNotEmpty || p.description.isNotEmpty)
            Text(
              p.tagline.isNotEmpty ? '"${p.tagline}" ${p.description}' : p.description,
              style: t.bodyMedium?.copyWith(color: CnnoColors.muted, height: 1.4),
            ),
          if (p.hasOptions) ...[
            const SizedBox(height: 18),
            Text('Flavour', style: t.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final v in p.variants)
                  ChoiceChip(
                    label: Text('${v.name} · ${rm(v.price)}'),
                    selected: v == _variant,
                    labelStyle: TextStyle(
                        color: v == _variant ? Colors.white : CnnoColors.text, fontWeight: FontWeight.w600),
                    onSelected: (_) => setState(() => _variant = v),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 18),
          Text('Quantity', style: t.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: QuantityStepper(value: _qty, min: 1, large: true, onChanged: (v) => setState(() => _qty = v)),
          ),
          const SizedBox(height: 14),
          Text('Pre-order: choose your pickup or delivery date at checkout.',
              style: t.bodySmall?.copyWith(color: CnnoColors.available)),
        ],
      ),
    );
  }
}
