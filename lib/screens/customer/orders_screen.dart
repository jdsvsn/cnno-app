import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/order.dart';
import '../../services/order_repository.dart';
import '../../state/session.dart';
import '../../theme.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';
import 'order_detail_screen.dart';

/// FR-09 Track order status, FR-14 View past orders.
class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  late final Stream<List<CnnoOrder>> _stream =
      context.read<OrderRepository>().watchMyOrders(context.read<Session>().user!.uid);

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return CnnoPage(
      title: 'My orders',
      child: StreamBuilder<List<CnnoOrder>>(
        stream: _stream,
        builder: (context, snap) {
          if (snap.hasError) {
            return const EmptyState(icon: Icons.wifi_off, message: 'Could not load your orders.');
          }
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final orders = snap.data!;
          if (orders.isEmpty) {
            return const EmptyState(icon: Icons.receipt_long_outlined, message: 'You have no orders yet.');
          }
          final active = orders.where((o) => o.status != OrderStatus.completed).toList();
          final past = orders.where((o) => o.status == OrderStatus.completed).toList();
          Widget tile(CnnoOrder o) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: CnnoCard(
                  onTap: () => Navigator.of(context)
                      .push(MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: o.id))),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Order ${o.label}', style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 2),
                            Text('${o.fulfilment.label} ${shortDate(o.preferredDate)} · ${rm(o.total)}',
                                style: t.bodySmall?.copyWith(color: CnnoColors.muted)),
                          ],
                        ),
                      ),
                      StatusPill(o.status),
                    ],
                  ),
                ),
              );
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            children: [
              if (active.isNotEmpty) ...[
                Text('Current', style: t.titleSmall?.copyWith(color: CnnoColors.muted)),
                const SizedBox(height: 8),
                ...active.map(tile),
              ],
              if (past.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Past orders', style: t.titleSmall?.copyWith(color: CnnoColors.muted)),
                const SizedBox(height: 8),
                ...past.map(tile),
              ],
            ],
          );
        },
      ),
    );
  }
}
