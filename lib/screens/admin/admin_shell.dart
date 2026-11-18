import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/product_repository.dart';
import '../../state/session.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'admin_orders_screen.dart';
import 'admin_products_screen.dart';

/// Admin bottom navigation: Orders, Products, Reports, Settings.
class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          AdminOrdersScreen(),
          AdminProductsScreen(),
          _ReportsPlaceholder(),
          _SettingsScreen(),
        ],
      ),
      bottomNavigationBar: CnnoBottomNav(
        labels: const ['Orders', 'Products', 'Reports', 'Settings'],
        index: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}

class _ReportsPlaceholder extends StatelessWidget {
  const _ReportsPlaceholder();

  @override
  Widget build(BuildContext context) => const CnnoPage(
        title: 'Reports',
        child: EmptyState(icon: Icons.insights_outlined, message: 'Reports are planned for a later version.'),
      );
}

class _SettingsScreen extends StatefulWidget {
  const _SettingsScreen();

  @override
  State<_SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<_SettingsScreen> {
  bool _seeding = false;

  Future<void> _seed() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Load CNNO menu?'),
        content: const Text(
            'This writes the agreed menu and prices to the database. Products with the same name are reset to the agreed prices.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Load menu')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _seeding = true);
    try {
      await context.read<ProductRepository>().seedMenu();
      if (mounted) showMessage(context, 'Menu loaded');
    } catch (_) {
      if (mounted) showMessage(context, 'Could not load the menu');
    } finally {
      if (mounted) setState(() => _seeding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final session = context.watch<Session>();
    return CnnoPage(
      title: 'Settings',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        children: [
          CnnoCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(session.user!.name, style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              Text('${session.user!.email} · Admin', style: t.bodySmall?.copyWith(color: CnnoColors.muted)),
            ]),
          ),
          const SizedBox(height: 16),
          CnnoCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Menu data', style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('Load the agreed CNNO menu and prices into the app.',
                  style: t.bodySmall?.copyWith(color: CnnoColors.muted)),
              const SizedBox(height: 10),
              FilledButton(
                onPressed: _seeding ? null : _seed,
                child: Text(_seeding ? 'Loading...' : 'Load CNNO menu'),
              ),
            ]),
          ),
          const SizedBox(height: 24),
          OutlinedButton(onPressed: session.logOut, child: const Text('Log out')),
        ],
      ),
    );
  }
}
