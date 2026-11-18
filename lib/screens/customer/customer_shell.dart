import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/cart.dart';
import '../../widgets/common.dart';
import 'assistant_screen.dart';
import 'cart_screen.dart';
import 'menu_screen.dart';
import 'orders_screen.dart';
import 'profile_screen.dart';

/// Customer bottom navigation: Menu, Cart, Orders, Assistant, Profile.
class CustomerShell extends StatefulWidget {
  const CustomerShell({super.key});

  static void goToTab(BuildContext context, int index) =>
      context.findAncestorStateOfType<_CustomerShellState>()?.setTab(index);

  static const menu = 0, cart = 1, orders = 2, assistant = 3, profile = 4;

  @override
  State<CustomerShell> createState() => _CustomerShellState();
}

class _CustomerShellState extends State<CustomerShell> {
  int _index = 0;

  void setTab(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    final count = context.watch<Cart>().count;
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          MenuScreen(),
          CartScreen(),
          OrdersScreen(),
          AssistantScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: CnnoBottomNav(
        labels: const ['Menu', 'Cart', 'Orders', 'Assistant', 'Profile'],
        index: _index,
        badges: {CustomerShell.cart: count},
        onTap: setTab,
      ),
    );
  }
}
