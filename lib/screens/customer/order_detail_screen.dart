import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/order.dart';
import '../../services/order_repository.dart';
import '../../theme.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';

/// UI-06 Order status (FR-09). Also used by the admin to view an order.
class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({super.key, required this.orderId, this.justPlaced = false, this.adminView = false});
  final String orderId;
  final bool justPlaced;
  final bool adminView;

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late final Stream<CnnoOrder> _stream = context.read<OrderRepository>().watchOrder(widget.orderId);

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return StreamBuilder<CnnoOrder>(
      stream: _stream,
      builder: (context, snap) {
        if (snap.hasError) {
          return const CnnoPage(
              title: 'Order', showBack: true,
              child: EmptyState(icon: Icons.error_outline, message: 'Could not load this order.'));
        }
        if (!snap.hasData) {
          return const CnnoPage(title: 'Order', showBack: true, child: Center(child: CircularProgressIndicator()));
        }
        final o = snap.data!;
        final flow = OrderStatus.flowFor(o.fulfilment);
        final current = flow.indexOf(o.status);
        return CnnoPage(
          title: 'Order ${o.label}',
          showBack: true,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            children: [
              if (widget.justPlaced)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text('Thank you! Your order is placed. A receipt is on its way to your email.',
                      style: t.bodyMedium?.copyWith(color: CnnoColors.available)),
                ),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(color: CnnoColors.primary, borderRadius: BorderRadius.circular(18)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Current status', style: t.labelSmall?.copyWith(color: const Color(0xFFF3C9D1))),
                    const SizedBox(height: 4),
                    Text(o.status.label,
                        style: t.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text('${o.fulfilment.label} on ${longDate(o.preferredDate)}, ${o.preferredTime}',
                        style: t.bodySmall?.copyWith(color: Colors.white)),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              CnnoCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    for (var i = 0; i < flow.length; i++)
                      _Step(label: flow[i].label, done: i <= current, isCurrent: i == current),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              CnnoCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Order summary', style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    for (final i in o.items)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(children: [
                          Expanded(
                              child: Text('${i.quantity} x ${i.name}',
                                  style: t.bodyMedium?.copyWith(color: CnnoColors.muted))),
                          Text(rm(i.lineTotal)),
                        ]),
                      ),
                    const Divider(height: 20, color: CnnoColors.softPink),
                    Row(children: [
                      Expanded(child: Text('Total', style: t.titleMedium)),
                      Text(rm(o.total), style: t.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                    ]),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              CnnoCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Details', style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    if (widget.adminView) _kv(t, 'Customer', '${o.customerName} (${o.customerEmail})'),
                    _kv(t, 'Phone', o.phone),
                    if (o.fulfilment == Fulfilment.delivery) _kv(t, 'Address', o.address),
                    _kv(t, 'Payment', '${o.paymentMethod} (outside the app)'),
                    _kv(t, 'Placed', longDate(o.createdAt)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static Widget _kv(TextTheme t, String k, String v) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 90, child: Text(k, style: t.bodyMedium?.copyWith(color: CnnoColors.muted))),
          Expanded(child: Text(v.isEmpty ? '-' : v, style: t.bodyMedium)),
        ]),
      );
}

class _Step extends StatelessWidget {
  const _Step({required this.label, required this.done, required this.isCurrent});
  final String label;
  final bool done;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 11,
            backgroundColor: done ? CnnoColors.primary : CnnoColors.softPink,
            child: done ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label + (isCurrent ? '  (now)' : ''),
              style: t.bodyLarge?.copyWith(
                color: done ? CnnoColors.text : CnnoColors.muted,
                fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
