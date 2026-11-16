import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../state/market_store.dart';
import '../widgets/common.dart';
import '../widgets/listing_card.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.onSell});

  final VoidCallback onSell;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<MarketStore>();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final mine = store.myListings;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          PopupMenuButton<ThemeMode>(
            tooltip: 'Theme',
            icon: const Icon(Icons.palette_outlined),
            initialValue: store.themeMode,
            onSelected: store.setThemeMode,
            itemBuilder: (_) => const [
              PopupMenuItem(value: ThemeMode.system, child: Text('System theme')),
              PopupMenuItem(value: ThemeMode.light, child: Text('Light')),
              PopupMenuItem(value: ThemeMode.dark, child: Text('Dark')),
            ],
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: scheme.primaryContainer,
                    child: const Text('😎', style: TextStyle(fontSize: 44)),
                  ),
                  const SizedBox(height: 12),
                  Text('Alex Johnson', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                  Text('San Francisco, CA · Member since 2026', style: TextStyle(color: scheme.onSurfaceVariant)),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      _Stat(value: '${mine.length}', label: 'Listings'),
                      _Stat(value: '${mine.where((l) => l.sold).length}', label: 'Sold'),
                      _Stat(value: '${store.favoriteListings.length}', label: 'Saved'),
                      _Stat(value: '${store.conversations.length}', label: 'Chats'),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('My listings', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
          ),
          if (mine.isEmpty)
            SliverToBoxAdapter(
              child: EmptyState(
                icon: Icons.sell_outlined,
                title: 'You haven\'t listed anything',
                message: 'Turn the things you don\'t use into cash in under a minute.',
                action: FilledButton.icon(
                  onPressed: onSell,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Sell an item'),
                ),
              ),
            )
          else
            ListingSliverGrid(listings: mine, heroScope: 'mine'),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Card.filled(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            children: [
              Text(value, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              Text(label, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
