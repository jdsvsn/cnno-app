import 'package:flutter/material.dart';

import '../models/order.dart';
import '../models/product.dart';
import '../theme.dart';

/// Striped awning band at the top of every screen (three reds from Figma).
class Awning extends StatelessWidget {
  const Awning({super.key});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return SizedBox(
      height: top + 8,
      width: double.infinity,
      child: const CustomPaint(painter: _AwningPainter()),
    );
  }
}

class _AwningPainter extends CustomPainter {
  const _AwningPainter();
  static const _colors = [CnnoColors.primary, CnnoColors.stripe, CnnoColors.maroon];

  @override
  void paint(Canvas canvas, Size size) {
    const w = 28.0;
    var i = 0;
    for (double x = 0; x < size.width; x += w) {
      canvas.drawRect(Rect.fromLTWH(x, 0, w, size.height),
          Paint()..color = _colors[i % _colors.length]);
      i++;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Standard page: awning, optional back button and title, content, bottom bar.
class CnnoPage extends StatelessWidget {
  const CnnoPage({
    super.key,
    this.title,
    this.showBack = false,
    required this.child,
    this.bottom,
    this.actions = const [],
  });

  final String? title;
  final bool showBack;
  final Widget child;
  final Widget? bottom;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      body: Column(
        children: [
          const Awning(),
          if (title != null)
            Padding(
              padding: EdgeInsets.fromLTRB(showBack ? 8 : 20, 12, 12, 8),
              child: Row(
                children: [
                  if (showBack)
                    IconButton(
                      tooltip: 'Back',
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.chevron_left, size: 28),
                    ),
                  Expanded(
                    child: Text(title!,
                        style: t.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
                  ),
                  ...actions,
                ],
              ),
            ),
          Expanded(child: child),
          if (bottom != null)
            SafeArea(
              top: false,
              child: Padding(padding: const EdgeInsets.fromLTRB(20, 8, 20, 12), child: bottom),
            ),
        ],
      ),
    );
  }
}

/// White rounded card used across the mockup.
class CnnoCard extends StatelessWidget {
  const CnnoCard({super.key, required this.child, this.padding = const EdgeInsets.all(14), this.onTap});
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: CnnoColors.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class ProductImage extends StatelessWidget {
  const ProductImage({super.key, this.asset, this.url, this.size = 64, this.fit = BoxFit.contain});
  final String? asset;
  final String? url;
  final double size;
  final BoxFit fit;

  factory ProductImage.of(Product p, {double size = 64}) =>
      ProductImage(asset: p.imageAsset, url: p.imageUrl, size: size);

  @override
  Widget build(BuildContext context) {
    final fallback = Icon(Icons.bakery_dining, size: size * 0.6, color: CnnoColors.muted);
    Widget img;
    if (url != null && url!.isNotEmpty) {
      img = Image.network(url!, fit: fit, errorBuilder: (_, _, _) => fallback);
    } else if (asset != null && asset!.isNotEmpty) {
      img = Image.asset(asset!, fit: fit, errorBuilder: (_, _, _) => fallback);
    } else {
      img = fallback;
    }
    return SizedBox(width: size, height: size, child: Center(child: img));
  }
}

/// Availability shown as text, not only colour (FR-04).
class AvailabilityText extends StatelessWidget {
  const AvailabilityText({super.key, required this.available, this.pill = false});
  final bool available;
  final bool pill;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: available ? CnnoColors.available : CnnoColors.muted,
          fontWeight: FontWeight.w500,
        );
    final text = Text(available ? 'Available' : 'Sold out', style: style);
    if (!pill) return text;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: available ? CnnoColors.availableBg : CnnoColors.softPink,
        borderRadius: BorderRadius.circular(20),
      ),
      child: text,
    );
  }
}

/// Order status pill (text always shown).
class StatusPill extends StatelessWidget {
  const StatusPill(this.status, {super.key});
  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (status) {
      OrderStatus.pending => (CnnoColors.softPink, CnnoColors.text),
      OrderStatus.preparing => (const Color(0xFFF6D7DD), CnnoColors.primary),
      OrderStatus.ready || OrderStatus.outForDelivery => (CnnoColors.availableBg, CnnoColors.available),
      OrderStatus.completed => (const Color(0xFFEDE7E8), CnnoColors.muted),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(status.label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: fg, fontWeight: FontWeight.w600)),
    );
  }
}

class QuantityStepper extends StatelessWidget {
  const QuantityStepper({super.key, required this.value, required this.onChanged, this.large = false, this.min = 0});
  final int value;
  final ValueChanged<int> onChanged;
  final bool large;
  final int min;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    Widget btn(IconData icon, VoidCallback? onTap, bool filled, String tip) => IconButton(
          tooltip: tip,
          onPressed: onTap,
          style: IconButton.styleFrom(
            backgroundColor: filled ? CnnoColors.primary : CnnoColors.softPink,
            foregroundColor: filled ? Colors.white : CnnoColors.text,
            minimumSize: Size.square(large ? 44 : 32),
            padding: EdgeInsets.zero,
          ),
          icon: Icon(icon, size: large ? 22 : 18),
        );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        btn(Icons.remove, value > min ? () => onChanged(value - 1) : null, false, 'Decrease'),
        SizedBox(
          width: large ? 48 : 32,
          child: Text('$value',
              textAlign: TextAlign.center,
              style: (large ? t.titleLarge : t.titleMedium)?.copyWith(fontWeight: FontWeight.w600)),
        ),
        btn(Icons.add, () => onChanged(value + 1), true, 'Increase'),
      ],
    );
  }
}

/// Text-only bottom navigation with a top indicator, as in the mockup.
class CnnoBottomNav extends StatelessWidget {
  const CnnoBottomNav({super.key, required this.labels, required this.index, required this.onTap, this.badges = const {}});
  final List<String> labels;
  final int index;
  final ValueChanged<int> onTap;
  final Map<int, int> badges;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Material(
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 58,
          child: Row(
            children: [
              for (var i = 0; i < labels.length; i++)
                Expanded(
                  child: InkWell(
                    onTap: () => onTap(i),
                    child: Column(
                      children: [
                        Container(
                          height: 3,
                          width: 36,
                          color: i == index ? CnnoColors.primary : Colors.transparent,
                        ),
                        const Spacer(),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(labels[i],
                                style: t.labelMedium?.copyWith(
                                  color: i == index ? CnnoColors.primary : CnnoColors.muted,
                                  fontWeight: i == index ? FontWeight.w700 : FontWeight.w500,
                                )),
                            if ((badges[i] ?? 0) > 0) ...[
                              const SizedBox(width: 4),
                              CircleAvatar(
                                radius: 8,
                                backgroundColor: CnnoColors.primary,
                                child: Text('${badges[i]}',
                                    style: const TextStyle(fontSize: 9, color: Colors.white)),
                              ),
                            ],
                          ],
                        ),
                        const Spacer(),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.message, this.action});
  final IconData icon;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 56, color: CnnoColors.muted),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: CnnoColors.muted)),
            if (action != null) ...[const SizedBox(height: 16), action!],
          ]),
        ),
      );
}

void showMessage(BuildContext context, String text) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));
}
