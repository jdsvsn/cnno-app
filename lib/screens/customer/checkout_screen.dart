import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config.dart';
import '../../models/order.dart';
import '../../services/order_repository.dart';
import '../../state/cart.dart';
import '../../state/session.dart';
import '../../theme.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';
import 'order_detail_screen.dart';

/// UI-05 Checkout and pre-order (FR-06, FR-07, FR-08).
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _form = GlobalKey<FormState>();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  Fulfilment _fulfilment = Fulfilment.pickup;
  DateTime? _date;
  TimeOfDay? _time;
  String _payment = AppConfig.paymentMethods.first;
  bool _busy = false;
  String? _dateError;
  String? _timeError;

  @override
  void dispose() {
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final first = earliestPreorderDate(DateTime.now(), AppConfig.preorderLeadDays);
    final d = await showDatePicker(
      context: context,
      firstDate: first,
      lastDate: first.add(const Duration(days: 60)),
      initialDate: _date ?? first,
      helpText: 'Preferred ${_fulfilment.label.toLowerCase()} date',
    );
    if (d != null) {
      setState(() {
        _date = d;
        _dateError = null;
      });
    }
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(context: context, initialTime: _time ?? const TimeOfDay(hour: 10, minute: 0));
    if (t != null) {
      setState(() {
        _time = t;
        _timeError = null;
      });
    }
  }

  Future<void> _place() async {
    final formOk = _form.currentState!.validate();
    setState(() {
      _dateError = _date == null ? 'Please choose a preferred date' : null;
      _timeError = _time == null ? 'Please choose a preferred time' : null;
    });
    if (!formOk || _date == null || _time == null) return;

    final cart = context.read<Cart>();
    final user = context.read<Session>().user!;
    final nav = Navigator.of(context);
    setState(() => _busy = true);
    try {
      final id = await context.read<OrderRepository>().placeOrder(
            user: user,
            items: cart.items,
            fulfilment: _fulfilment,
            preferredDate: _date!,
            preferredTime: _time!.format(context),
            phone: _phone.text.trim(),
            address: _address.text.trim(),
            paymentMethod: _payment,
          );
      cart.clear();
      nav.popUntil((r) => r.isFirst);
      nav.push(MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: id, justPlaced: true)));
    } catch (e) {
      if (mounted) showMessage(context, 'Could not place the order. Check your connection and try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cart = context.watch<Cart>();
    Widget label(String s) => Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 6),
          child: Text(s, style: t.bodySmall?.copyWith(color: CnnoColors.text)),
        );
    Widget heading(String s) => Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 2),
          child: Text(s, style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        );
    Widget pickerField(String text, bool empty, VoidCallback onTap, String? error, IconData icon) =>
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: InputDecorator(
            decoration: InputDecoration(errorText: error, suffixIcon: Icon(icon, color: CnnoColors.muted)),
            child: Text(text,
                style: t.bodyLarge?.copyWith(color: empty ? const Color(0xFFB9A2A7) : CnnoColors.text)),
          ),
        );

    return CnnoPage(
      title: 'Checkout',
      showBack: true,
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FilledButton(
            onPressed: _busy || cart.isEmpty ? null : _place,
            child: _busy
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                : const Text('Place order'),
          ),
          const SizedBox(height: 8),
          Text('An email confirmation will be sent after you place the order.',
              style: t.bodySmall?.copyWith(color: CnnoColors.muted)),
        ],
      ),
      child: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          children: [
            heading('Fulfilment'),
            const SizedBox(height: 6),
            SegmentedButton<Fulfilment>(
              showSelectedIcon: false,
              style: SegmentedButton.styleFrom(
                backgroundColor: CnnoColors.softPink,
                selectedBackgroundColor: Colors.white,
                selectedForegroundColor: CnnoColors.primary,
                side: BorderSide.none,
              ),
              segments: [for (final f in Fulfilment.values) ButtonSegment(value: f, label: Text(f.label))],
              selected: {_fulfilment},
              onSelectionChanged: (s) => setState(() => _fulfilment = s.first),
            ),
            if (_fulfilment == Fulfilment.delivery)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('CNNO books delivery on Grab. The fee is quoted separately.',
                    style: t.bodySmall?.copyWith(color: CnnoColors.muted)),
              ),
            label('Preferred date (pre-order)'),
            pickerField(_date == null ? 'Select a date' : longDate(_date!), _date == null, _pickDate,
                _dateError, Icons.calendar_today_outlined),
            label('Preferred time'),
            pickerField(_time == null ? 'Select a time' : _time!.format(context), _time == null, _pickTime,
                _timeError, Icons.schedule),
            label('Phone number'),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(hintText: '01X XXX XXXX'),
              validator: (v) {
                final digits = (v ?? '').replaceAll(RegExp(r'[^0-9]'), '');
                if (digits.isEmpty) return 'Please enter your phone number';
                if (digits.length < 9 || digits.length > 12) return 'Please enter a valid phone number';
                return null;
              },
            ),
            if (_fulfilment == Fulfilment.delivery) ...[
              label('Delivery address'),
              TextFormField(
                controller: _address,
                maxLines: 2,
                decoration: const InputDecoration(hintText: 'Street, area, city'),
                validator: (v) => _fulfilment == Fulfilment.delivery && (v ?? '').trim().isEmpty
                    ? 'Please enter your delivery address'
                    : null,
              ),
            ],
            heading('Payment'),
            const SizedBox(height: 6),
            CnnoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Pay outside the app', style: t.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('CNNO will send payment details after you place the order.',
                      style: t.bodySmall?.copyWith(color: CnnoColors.muted)),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: _payment,
                    decoration: const InputDecoration(labelText: 'Payment method'),
                    items: [
                      for (final m in AppConfig.paymentMethods) DropdownMenuItem(value: m, child: Text(m)),
                    ],
                    onChanged: (v) => setState(() => _payment = v ?? _payment),
                  ),
                ],
              ),
            ),
            heading('Order summary'),
            const SizedBox(height: 6),
            CnnoCard(
              child: Column(
                children: [
                  for (final i in cart.items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(children: [
                        Expanded(
                            child: Text('${i.quantity} x ${i.displayName}',
                                style: t.bodyMedium?.copyWith(color: CnnoColors.muted))),
                        Text(rm(i.lineTotal), style: t.bodyMedium),
                      ]),
                    ),
                  if (_date != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(children: [
                        Expanded(child: Text(_fulfilment.label, style: t.bodyMedium?.copyWith(color: CnnoColors.muted))),
                        Text('${longDate(_date!)}${_time != null ? ', ${_time!.format(context)}' : ''}',
                            style: t.bodyMedium),
                      ]),
                    ),
                  const Divider(height: 20, color: CnnoColors.softPink),
                  Row(children: [
                    Expanded(child: Text('Total', style: t.titleMedium)),
                    Text(rm(cart.subtotal), style: t.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
