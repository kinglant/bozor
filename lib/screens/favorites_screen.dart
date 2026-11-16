import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../state/market_store.dart';
import '../widgets/common.dart';
import '../widgets/listing_card.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key, required this.onBrowse});

  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<MarketStore>().favoriteListings;

    return Scaffold(
      appBar: AppBar(title: const Text('Saved items')),
      body: favorites.isEmpty
          ? EmptyState(
              icon: Icons.favorite_border_rounded,
              title: 'Nothing saved yet',
              message: 'Tap the heart on any item to keep track of it here.',
              action: FilledButton(onPressed: onBrowse, child: const Text('Browse items')),
            )
          : CustomScrollView(
              slivers: [
                const SliverToBoxAdapter(child: SizedBox(height: 8)),
                ListingSliverGrid(listings: favorites, heroScope: 'saved'),
              ],
            ),
    );
  }
}
