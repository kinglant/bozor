import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../data/sample_data.dart';
import '../state/market_store.dart';
import '../widgets/common.dart';
import 'chat_screen.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<MarketStore>();
    final chats = store.conversations;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: chats.isEmpty
          ? const EmptyState(
              icon: Icons.forum_outlined,
              title: 'No messages yet',
              message: 'When you contact a seller, your conversation will appear here.',
            )
          : ListView.separated(
              itemCount: chats.length,
              separatorBuilder: (_, _) => const Divider(height: 1, indent: 88),
              itemBuilder: (context, i) {
                final chat = chats[i];
                final listing = store.listingById(chat.listingId)!;
                final seller = sellerById(listing.sellerId);
                final last = chat.messages.last;
                final unread = chat.unread > 0;

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  leading: SizedBox.square(dimension: 56, child: ListingImage(listing: listing, radius: 12)),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          listing.isMine ? listing.title : seller.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontWeight: unread ? FontWeight.w800 : FontWeight.w600),
                        ),
                      ),
                      Text(timeAgo(last.at), style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                  subtitle: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${last.fromMe ? 'You: ' : ''}${last.text}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: unread ? scheme.onSurface : scheme.onSurfaceVariant),
                        ),
                      ),
                      if (unread)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(color: scheme.primary, borderRadius: BorderRadius.circular(10)),
                          child: Text('${chat.unread}', style: TextStyle(color: scheme.onPrimary, fontSize: 12)),
                        ),
                    ],
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => ChatScreen(listingId: listing.id)),
                  ),
                );
              },
            ),
    );
  }
}
