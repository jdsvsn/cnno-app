import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/order.dart';
import '../../services/order_repository.dart';
import '../../theme.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';
import '../customer/order_detail_screen.dart';

/// UI-08 Admin orders (FR-12 view and update status, FR-13 by date and method).
class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

enum _StatusFilter { all, pending, preparing, ready, completed }

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  late final Stream<List<CnnoOrder>> _stream = context.read<OrderRepository>().watchAllOrders();
  _StatusFilter _status = _StatusFilter.all;
  Fulfilment? _method;
  DateTime? _date;

  bool _matches(CnnoOrder o) {
    final statusOk = switch (_status) {
      _StatusFilter.all => true,
      _StatusFilter.pending => o.status == OrderStatus.pending,
      _StatusFilter.preparing => o.status == OrderStatus.preparing,
      _StatusFilter.ready => o.status == OrderStatus.ready || o.status == OrderStatus.outForDelivery,
      _StatusFilter.completed => o.status == OrderStatus.completed,
    };
    final methodOk = _method == null || o.fulfilment == _method;
    final d = o.preferredDate;
    final dateOk = _date == null || (d.year == _date!.year && d.month == _date!.month && d.day == _date!.day);
    return statusOk && methodOk && dateOk;
  }

  Future<void> _updateStatus(CnnoOrder o) async {
    final options = OrderStatus.nextOptions(o.status, o.fulfilment);
    if (options.isEmpty) {
      showMessage(context, 'Order ${o.label} is already completed');
      return;
    }
    final picked = await showModalBottomSheet<OrderStatus>(
      context: context,
      showDragHandle: true,
      builder: (c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Update ${o.label}', style: Theme.of(c).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final s in options)
              ListTile(title: Text(s.label), onTap: () => Navigator.pop(c, s)),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (picked == null || !mounted) return;
    try {
      await context.read<OrderRepository>().updateStatus(o.id, picked);
      if (mounted) showMessage(context, '${o.label} is now ${picked.label}');
    } catch (_) {
      if (mounted) showMessage(context, 'Could not update the status');
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 120)),
      initialDate: _date ?? now,
      helpText: 'Show orders for',
    );
    if (d != null) setState(() => _date = d);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return CnnoPage(
      title: 'Admin dashboard',
      child: StreamBuilder<List<CnnoOrder>>(
        stream: _stream,
        builder: (context, snap) {
          if (snap.hasError) {
            return const EmptyState(icon: Icons.lock_outline, message: 'Could not load orders.');
          }
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final all = snap.data!;
          int count(bool Function(CnnoOrder) f) => all.where(f).length;
          final shown = all.where(_matches).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            children: [
              Row(children: [
                _Stat(count((o) => o.status == OrderStatus.pending), 'New'),
                const SizedBox(width: 10),
                _Stat(count((o) => o.status == OrderStatus.preparing), 'Preparing'),
                const SizedBox(width: 10),
                _Stat(count((o) => o.status == OrderStatus.ready || o.status == OrderStatus.outForDelivery),
                    'Ready'),
              ]),
              const SizedBox(height: 14),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [
                  for (final f in _StatusFilter.values)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(switch (f) {
                          _StatusFilter.all => 'All',
                          _StatusFilter.pending => 'Pending',
                          _StatusFilter.preparing => 'Preparing',
                          _StatusFilter.ready => 'Ready',
                          _StatusFilter.completed => 'Completed',
                        }),
                        selected: _status == f,
                        labelStyle: TextStyle(
                            color: _status == f ? Colors.white : CnnoColors.text, fontWeight: FontWeight.w600),
                        onSelected: (_) => setState(() => _status = f),
                      ),
                    ),
                ]),
              ),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40)),
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today_outlined, size: 16),
                    label: Text(_date == null ? 'Any date' : shortDate(_date!)),
                  ),
                ),
                if (_date != null)
                  IconButton(
                      tooltip: 'Clear date', onPressed: () => setState(() => _date = null), icon: const Icon(Icons.close)),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<Fulfilment?>(
                    initialValue: _method,
                    isDense: true,
                    decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All methods')),
                      for (final f in Fulfilment.values) DropdownMenuItem(value: f, child: Text(f.label)),
                    ],
                    onChanged: (v) => setState(() => _method = v),
                  ),
                ),
              ]),
              const SizedBox(height: 14),
              if (shown.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text('No orders match.',
                      textAlign: TextAlign.center, style: t.bodyMedium?.copyWith(color: CnnoColors.muted)),
                ),
              for (final o in shown)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: CnnoCard(
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => OrderDetailScreen(orderId: o.id, adminView: true))),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(children: [
                          Expanded(
                            child: Text('${o.label}  ${o.customerName}',
                                style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                          ),
                          StatusPill(o.status),
                        ]),
                        const SizedBox(height: 6),
                        Row(children: [
                          Expanded(
                            child: Text(
                                '${o.fulfilment.label} ${shortDate(o.preferredDate)}, ${o.preferredTime}',
                                style: t.bodySmall?.copyWith(color: CnnoColors.muted)),
                          ),
                          Text(rm(o.total),
                              style: t.titleSmall?.copyWith(color: CnnoColors.primary, fontWeight: FontWeight.w700)),
                        ]),
                        const SizedBox(height: 10),
                        FilledButton.tonal(
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(38),
                            backgroundColor: CnnoColors.softPink,
                            foregroundColor: CnnoColors.primary,
                          ),
                          onPressed: o.status == OrderStatus.completed ? null : () => _updateStatus(o),
                          child: const Text('Update status'),
                        ),
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
}

class _Stat extends StatelessWidget {
  const _Stat(this.value, this.label);
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Expanded(
      child: CnnoCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('$value', style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
          Text(label, style: t.bodySmall?.copyWith(color: CnnoColors.muted)),
        ]),
      ),
    );
  }
}
