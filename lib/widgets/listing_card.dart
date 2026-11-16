import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../screens/listing_detail_screen.dart';
import '../state/market_store.dart';
import 'common.dart';

class ListingCard extends StatelessWidget {
  const ListingCard({super.key, required this.listing, required this.heroScope});

  final Listing listing;

  /// Hero tags must be unique per screen (tabs stay alive in an IndexedStack).
  final String heroScope;

  String get heroTag => '$heroScope-${listing.id}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final favorite = context.select<MarketStore, bool>((s) => s.isFavorite(listing.id));

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ListingDetailScreen(listingId: listing.id, heroTag: heroTag)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Hero(tag: heroTag, child: ListingImage(listing: listing, radius: 16)),
                Positioned(
                  top: 6,
                  right: 6,
                  child: Material(
                    color: scheme.surface.withValues(alpha: 0.9),
                    shape: const CircleBorder(),
                    child: IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: favorite ? 'Remove from saved' : 'Save',
                      icon: Icon(
                        favorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: favorite ? Colors.redAccent : scheme.onSurface,
                        size: 20,
                      ),
                      onPressed: () => context.read<MarketStore>().toggleFavorite(listing.id),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            formatPrice(listing.price),
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(listing.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 4),
          Text(
            '${listing.location.split(',').first} · ${timeAgo(listing.postedAt)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// Responsive grid of listing cards for use inside a CustomScrollView.
class ListingSliverGrid extends StatelessWidget {
  const ListingSliverGrid({super.key, required this.listings, required this.heroScope});

  final List<Listing> listings;
  final String heroScope;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 240,
          mainAxisSpacing: 18,
          crossAxisSpacing: 14,
          childAspectRatio: 0.62,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, i) => ListingCard(listing: listings[i], heroScope: heroScope),
          childCount: listings.length,
        ),
      ),
    );
  }
}
