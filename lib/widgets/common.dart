import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';

import '../models/models.dart';

const palettes = <List<Color>>[
  [Color(0xFFFFE0B2), Color(0xFFFFAB91)],
  [Color(0xFFC8E6C9), Color(0xFF80CBC4)],
  [Color(0xFFB3E5FC), Color(0xFF90CAF9)],
  [Color(0xFFE1BEE7), Color(0xFFB39DDB)],
  [Color(0xFFFFF59D), Color(0xFFFFCC80)],
  [Color(0xFFCFD8DC), Color(0xFF90A4AE)],
  [Color(0xFFF8BBD0), Color(0xFFF48FB1)],
  [Color(0xFFDCEDC8), Color(0xFFAED581)],
];

final _currency = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
String formatPrice(double price) => price == 0 ? 'Free' : _currency.format(price);

String timeAgo(DateTime time) {
  final d = DateTime.now().difference(time);
  if (d.inMinutes < 1) return 'just now';
  if (d.inHours < 1) return '${d.inMinutes}m ago';
  if (d.inDays < 1) return '${d.inHours}h ago';
  if (d.inDays < 7) return '${d.inDays}d ago';
  return DateFormat.MMMd().format(time);
}

String clockTime(DateTime time) => DateFormat.jm().format(time);

/// Path of the bundled PNG for an emoji, e.g. 🚲 → assets/emoji/1f6b2.png
String emojiAsset(String emoji) {
  final code = emoji.runes.where((r) => r != 0xFE0F).map((r) => r.toRadixString(16)).join('-');
  return 'assets/emoji/$code.png';
}

/// Shows the listing's first photo, or a gradient illustration when it has none.
class ListingImage extends StatelessWidget {
  const ListingImage({super.key, required this.listing, this.index = 0, this.radius = 0});

  final Listing listing;
  final int index;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final Widget child;
    if (listing.photos.isNotEmpty) {
      child = Image.memory(
        listing.photos[index.clamp(0, listing.photos.length - 1)],
        fit: BoxFit.cover,
        gaplessPlayback: true,
      );
    } else {
      final colors = palettes[listing.palette % palettes.length];
      child = DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors),
        ),
        child: FractionallySizedBox(
          widthFactor: 0.62,
          heightFactor: 0.62,
          // Emoji are bundled as PNGs (rendered from Noto Color Emoji) so they
          // look identical on every platform; the web renderer sometimes falls
          // back to a monochrome symbol font for emoji text.
          child: Image.asset(
            emojiAsset(listing.emoji),
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
            errorBuilder: (_, _, _) => FittedBox(child: Text(listing.emoji)),
          ),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Stack(
        fit: StackFit.expand,
        children: [
          child,
          if (listing.sold)
            ColoredBox(
              color: Colors.black45,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                  child: const Text('SOLD', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.2, color: Colors.black)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, required this.message, this.action});

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: scheme.primaryContainer, shape: BoxShape.circle),
              child: Icon(icon, size: 36, color: scheme.onPrimaryContainer),
            ),
            const SizedBox(height: 20),
            Text(title, style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(message, style: TextStyle(color: scheme.onSurfaceVariant), textAlign: TextAlign.center),
            if (action != null) ...[const SizedBox(height: 20), action!],
          ],
        ),
      ),
    );
  }
}
