import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'screens/admin/admin_shell.dart';
import 'screens/auth/login_screen.dart';
import 'screens/customer/customer_shell.dart';
import 'services/ai_service.dart';
import 'services/auth_service.dart';
import 'services/order_repository.dart';
import 'services/product_repository.dart';
import 'state/cart.dart';
import 'state/session.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const CnnoApp());
}

class CnnoApp extends StatelessWidget {
  const CnnoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (_) => AuthService()),
        Provider(create: (_) => ProductRepository()),
        Provider(create: (_) => OrderRepository()),
        Provider(create: (_) => AiService()),
        ChangeNotifierProvider(create: (c) => Session(c.read<AuthService>())),
        ChangeNotifierProvider(create: (_) => Cart()),
      ],
      child: MaterialApp(
        title: 'CNNO',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        home: const _Root(),
      ),
    );
  }
}

/// Opens login, the customer app or the admin dashboard based on the role.
class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    final session = context.watch<Session>();
    switch (session.state) {
      case SessionState.loading:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      case SessionState.signedOut:
        return const LoginScreen();
      case SessionState.signedIn:
        return session.user!.isAdmin
            ? AdminShell(key: ValueKey('admin-${session.user!.uid}'))
            : CustomerShell(key: ValueKey('customer-${session.user!.uid}'));
    }
  }
}
