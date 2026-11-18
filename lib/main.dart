import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
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
        builder: (context, child) => kIsWeb ? _PhoneFrame(child: child!) : child!,
        home: const _Root(),
      ),
    );
  }
}

/// On a laptop browser (demo only), show the app at phone size (390 x 844, as in Figma).
class _PhoneFrame extends StatelessWidget {
  const _PhoneFrame({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    if (size.width < 500) return child;
    return ColoredBox(
      color: const Color(0xFF3A0A14),
      child: Center(
        child: Container(
          width: 390,
          height: size.height < 884 ? size.height - 40 : 844,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(32)),
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              size: Size(390, size.height < 884 ? size.height - 40 : 844),
              padding: const EdgeInsets.only(top: 24),
            ),
            child: child,
          ),
        ),
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
