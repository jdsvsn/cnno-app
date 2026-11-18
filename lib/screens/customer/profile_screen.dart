import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config.dart';
import '../../data/menu_seed.dart';
import '../../state/cart.dart';
import '../../state/session.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final session = context.watch<Session>();
    final user = session.user!;
    return CnnoPage(
      title: 'Profile',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        children: [
          CnnoCard(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: CnnoColors.softPink,
                  child: Text(user.name.isEmpty ? '?' : user.name[0].toUpperCase(),
                      style: t.titleLarge?.copyWith(color: CnnoColors.primary)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(user.name, style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    Text(user.email, style: t.bodySmall?.copyWith(color: CnnoColors.muted)),
                  ]),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          CnnoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Favourite flavours', style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('Used for your Smart Recommendation.',
                    style: t.bodySmall?.copyWith(color: CnnoColors.muted)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final f in flavourOptions)
                      FilterChip(
                        label: Text(f),
                        selected: user.favouriteFlavours.contains(f),
                        labelStyle: TextStyle(
                            color: user.favouriteFlavours.contains(f) ? Colors.white : CnnoColors.text,
                            fontWeight: FontWeight.w600),
                        onSelected: (on) {
                          final next = [...user.favouriteFlavours];
                          on ? next.add(f) : next.remove(f);
                          session.setFavourites(next);
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: () {
              context.read<Cart>().clear();
              session.logOut();
            },
            child: const Text('Log out'),
          ),
          const SizedBox(height: 24),
          Text(AppConfig.brandText,
              textAlign: TextAlign.center, style: t.bodySmall?.copyWith(color: CnnoColors.muted)),
        ],
      ),
    );
  }
}
