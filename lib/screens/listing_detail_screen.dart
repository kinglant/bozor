import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../data/sample_data.dart';
import '../models/models.dart';
import '../state/market_store.dart';
import '../widgets/common.dart';
import '../widgets/listing_card.dart';
import 'chat_screen.dart';

class ListingDetailScreen extends StatefulWidget {
  const ListingDetailScreen({super.key, required this.listingId, this.heroTag});

  final String listingId;
  final String? heroTag;

  @override
  State<ListingDetailScreen> createState() => _ListingDetailScreenState();
}

class _ListingDetailScreenState extends State<ListingDetailScreen> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<MarketStore>();
    final listing = store.listingById(widget.listingId);
    if (listing == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(
          icon: Icons.inventory_2_outlined,
          title: 'Listing removed',
          message: 'This item is no longer available.',
        ),
      );
    }

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final seller = sellerById(listing.sellerId);
    final favorite = store.isFavorite(listing.id);
    final pages = listing.photos.isEmpty ? 1 : listing.photos.length;
    final more = store.moreFromSeller(listing);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: MediaQuery.sizeOf(context).width.clamp(0, 520) * 0.9,
            // Tonal buttons stay readable on top of light and dark images.
            leading: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: IconButton.filledTonal(
                tooltip: 'Back',
                onPressed: () => Navigator.maybePop(context),
                icon: const BackButtonIcon(),
              ),
            ),
            actions: [
              IconButton.filledTonal(
                tooltip: favorite ? 'Remove from saved' : 'Save',
                onPressed: () => store.toggleFavorite(listing.id),
                icon: Icon(
                  favorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: favorite ? Colors.redAccent : null,
                ),
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  PageView.builder(
                    itemCount: pages,
                    onPageChanged: (i) => setState(() => _page = i),
                    itemBuilder: (_, i) => i == 0
                        ? Hero(tag: widget.heroTag ?? 'detail-${listing.id}', child: ListingImage(listing: listing))
                        : ListingImage(listing: listing, index: i),
                  ),
                  if (pages > 1)
                    Positioned(
                      bottom: 12,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var i = 0; i < pages; i++)
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width: i == _page ? 18 : 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: i == _page ? Colors.white : Colors.white60,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        formatPrice(listing.price),
                        style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800, color: scheme.primary),
                      ),
                      const SizedBox(height: 4),
                      Text(listing.title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined, size: 16, color: scheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              '${listing.location} · Listed ${timeAgo(listing.postedAt)}',
                              style: TextStyle(color: scheme.onSurfaceVariant),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _InfoChip(icon: Icons.verified_outlined, label: listing.condition.label),
                          _InfoChip(icon: listing.category.icon, label: listing.category.label),
                          if (listing.sold) const _InfoChip(icon: Icons.sell_outlined, label: 'Sold'),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text('Description', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Text(listing.description, style: theme.textTheme.bodyLarge?.copyWith(height: 1.5)),
                      const SizedBox(height: 24),
                      _SellerCard(seller: seller),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: scheme.tertiaryContainer.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.shield_outlined, color: scheme.onTertiaryContainer),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text('Meet in a public place and check the item before you pay.'),
                            ),
                          ],
                        ),
                      ),
                      if (more.isNotEmpty) ...[
                        const SizedBox(height: 28),
                        Text(
                          'More from ${seller.name.split(' ').first}',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (more.isNotEmpty) ListingSliverGrid(listings: more, heroScope: 'more-${listing.id}'),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: listing.isMine ? _OwnerActions(listing: listing) : _BuyerActions(listing: listing),
        ),
      ),
    );
  }
}

class _BuyerActions extends StatelessWidget {
  const _BuyerActions({required this.listing});

  final Listing listing;

  @override
  Widget build(BuildContext context) {
    void openChat([String? draft]) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ChatScreen(listingId: listing.id, initialDraft: draft)),
      );
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            onPressed: () => openChat('Hi! Would you take ${formatPrice((listing.price * 0.85).roundToDouble())}?'),
            icon: const Icon(Icons.local_offer_outlined),
            label: const Text('Make offer'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.icon(
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            onPressed: openChat,
            icon: const Icon(Icons.chat_bubble_outline_rounded),
            label: const Text('Message'),
          ),
        ),
      ],
    );
  }
}

class _OwnerActions extends StatelessWidget {
  const _OwnerActions({required this.listing});

  final Listing listing;

  @override
  Widget build(BuildContext context) {
    final store = context.read<MarketStore>();
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (c) => AlertDialog(
                  title: const Text('Delete listing?'),
                  content: const Text('This can\'t be undone.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                    FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete')),
                  ],
                ),
              );
              if (ok == true && context.mounted) {
                Navigator.pop(context);
                store.deleteListing(listing.id);
              }
            },
            icon: const Icon(Icons.delete_outline_rounded),
            label: const Text('Delete'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.icon(
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            onPressed: () => store.toggleSold(listing.id),
            icon: Icon(listing.sold ? Icons.replay_rounded : Icons.check_circle_outline_rounded),
            label: Text(listing.sold ? 'Mark available' : 'Mark as sold'),
          ),
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(color: scheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon, size: 16), const SizedBox(width: 6), Text(label)],
      ),
    );
  }
}

class _SellerCard extends StatelessWidget {
  const _SellerCard({required this.seller});

  final Seller seller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card.outlined(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: scheme.primaryContainer,
              child: Text(seller.avatar, style: const TextStyle(fontSize: 26)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(seller.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                      const SizedBox(width: 2),
                      Text('${seller.rating.toStringAsFixed(1)} (${seller.reviews})'),
                      Flexible(
                        child: Text(
                          ' · Since ${seller.memberSince}',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: scheme.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Usually responds ${seller.responseTime}',
                    style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
