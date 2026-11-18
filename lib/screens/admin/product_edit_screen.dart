import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/product.dart';
import '../../services/product_repository.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

/// FR-11: add or edit a product, its prices and availability.
class ProductEditScreen extends StatefulWidget {
  const ProductEditScreen({super.key, this.product});
  final Product? product;

  @override
  State<ProductEditScreen> createState() => _ProductEditScreenState();
}

class _VariantFields {
  _VariantFields(String name, String price)
      : name = TextEditingController(text: name),
        price = TextEditingController(text: price);
  final TextEditingController name;
  final TextEditingController price;
  void dispose() {
    name.dispose();
    price.dispose();
  }
}

class _ProductEditScreenState extends State<ProductEditScreen> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.product?.name ?? '');
  late final _tagline = TextEditingController(text: widget.product?.tagline ?? '');
  late final _description = TextEditingController(text: widget.product?.description ?? '');
  late ProductCategory _category = widget.product?.category ?? ProductCategory.single;
  late bool _available = widget.product?.available ?? true;
  late final List<_VariantFields> _variants = (widget.product?.variants ?? const [ProductVariant(name: 'Single', price: 0)])
      .map((v) => _VariantFields(v.name, v.price == 0 ? '' : v.price.toStringAsFixed(2)))
      .toList();
  File? _photo;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _tagline.dispose();
    _description.dispose();
    for (final v in _variants) {
      v.dispose();
    }
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1200, imageQuality: 85);
    if (x != null) setState(() => _photo = File(x.path));
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    final repo = context.read<ProductRepository>();
    final nav = Navigator.of(context);
    try {
      String? url = widget.product?.imageUrl;
      if (_photo != null) url = await repo.uploadPhoto(_photo!);
      final p = Product(
        id: widget.product?.id ?? '',
        name: _name.text.trim(),
        category: _category,
        tagline: _tagline.text.trim(),
        description: _description.text.trim(),
        imageAsset: _photo != null ? null : widget.product?.imageAsset,
        imageUrl: url,
        available: _available,
        variants: [
          for (final v in _variants)
            ProductVariant(name: v.name.text.trim(), price: double.parse(v.price.text.trim())),
        ],
        sortOrder: widget.product?.sortOrder ?? 100,
      );
      await repo.save(p);
      nav.pop();
      if (mounted) showMessage(context, '${p.name} saved');
    } catch (_) {
      if (mounted) showMessage(context, 'Could not save the product');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    Widget label(String s) => Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 6),
          child: Text(s, style: t.bodySmall?.copyWith(color: CnnoColors.text)),
        );
    return CnnoPage(
      title: widget.product == null ? 'New product' : 'Edit product',
      showBack: true,
      bottom: FilledButton(
        onPressed: _saving ? null : _save,
        child: Text(_saving ? 'Saving...' : 'Save'),
      ),
      child: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          children: [
            Center(
              child: InkWell(
                onTap: _pickPhoto,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                  child: _photo != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16), child: Image.file(_photo!, fit: BoxFit.cover))
                      : widget.product != null
                          ? ProductImage.of(widget.product!, size: 120)
                          : const Icon(Icons.add_a_photo_outlined, size: 40, color: CnnoColors.muted),
                ),
              ),
            ),
            Center(child: TextButton(onPressed: _pickPhoto, child: const Text('Change photo'))),
            label('Name'),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(hintText: 'Product name'),
              validator: (v) => (v ?? '').trim().isEmpty ? 'Please enter a name' : null,
            ),
            label('Category'),
            DropdownButtonFormField<ProductCategory>(
              initialValue: _category,
              items: [
                for (final c in ProductCategory.values) DropdownMenuItem(value: c, child: Text(c.chipLabel)),
              ],
              onChanged: (v) => setState(() => _category = v ?? _category),
            ),
            label('Tagline (optional)'),
            TextFormField(controller: _tagline, decoration: const InputDecoration(hintText: 'e.g. The OG.')),
            label('Description'),
            TextFormField(controller: _description, maxLines: 3),
            label('Prices (RM)'),
            for (var i = 0; i < _variants.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _variants[i].name,
                        decoration: const InputDecoration(hintText: 'Option, e.g. OG + Pista'),
                        validator: (v) => (v ?? '').trim().isEmpty ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _variants[i].price,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(hintText: '0.00', prefixText: 'RM '),
                        validator: (v) {
                          final n = double.tryParse((v ?? '').trim());
                          return (n == null || n <= 0) ? 'Invalid' : null;
                        },
                      ),
                    ),
                    IconButton(
                      tooltip: 'Remove option',
                      onPressed: _variants.length == 1
                          ? null
                          : () => setState(() => _variants.removeAt(i).dispose()),
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                  ],
                ),
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => setState(() => _variants.add(_VariantFields('', ''))),
                icon: const Icon(Icons.add),
                label: const Text('Add option'),
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Available'),
              subtitle: Text(_available ? 'Customers can order this' : 'Shown as sold out'),
              value: _available,
              activeTrackColor: CnnoColors.available,
              onChanged: (v) => setState(() => _available = v),
            ),
          ],
        ),
      ),
    );
  }
}
