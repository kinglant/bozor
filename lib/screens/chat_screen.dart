import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../data/sample_data.dart';
import '../state/market_store.dart';
import '../widgets/common.dart';
import 'listing_detail_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.listingId, this.initialDraft});

  final String listingId;
  final String? initialDraft;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final _input = TextEditingController(text: widget.initialDraft);
  static const _quickReplies = ['Is this still available?', 'Can you do a lower price?', 'Where can we meet?'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<MarketStore>().markRead(widget.listingId);
    });
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _send([String? text]) {
    final value = text ?? _input.text;
    if (value.trim().isEmpty) return;
    context.read<MarketStore>().sendMessage(widget.listingId, value);
    if (text == null) _input.clear();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<MarketStore>();
    final listing = store.listingById(widget.listingId);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (listing == null) {
      return Scaffold(appBar: AppBar(), body: const Center(child: Text('This listing was removed.')));
    }

    final seller = sellerById(listing.sellerId);
    final messages = store.chatFor(widget.listingId).messages;
    final typing = store.typing.contains(widget.listingId);
    // Newest first, because the list is reversed (keeps the view pinned to the latest message).
    final items = messages.reversed.toList();

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: scheme.primaryContainer,
              child: Text(seller.avatar, style: const TextStyle(fontSize: 18)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(listing.isMine ? 'Your listing' : seller.name, style: theme.textTheme.titleMedium),
                  Text(
                    typing ? 'typing…' : 'Responds ${seller.responseTime}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: typing ? scheme.primary : scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Listing summary
          Material(
            color: scheme.surfaceContainerLow,
            child: InkWell(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => ListingDetailScreen(listingId: listing.id)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    SizedBox.square(dimension: 48, child: ListingImage(listing: listing, radius: 10)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(listing.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text(
                            formatPrice(listing.price),
                            style: TextStyle(fontWeight: FontWeight.w800, color: scheme.primary),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: messages.isEmpty
                ? EmptyState(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: 'Start the conversation',
                    message: 'Ask ${seller.name.split(' ').first} about "${listing.title}".',
                  )
                : ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                    itemCount: items.length + (typing ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (typing && i == 0) return const _TypingBubble();
                      final m = items[typing ? i - 1 : i];
                      return _Bubble(text: m.text, time: clockTime(m.at), fromMe: m.fromMe);
                    },
                  ),
          ),
          if (messages.isEmpty || messages.length < 3)
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  for (final q in _quickReplies)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(label: Text(q), onPressed: () => _send(q)),
                    ),
                ],
              ),
            ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      textCapitalization: TextCapitalization.sentences,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: 'Message…',
                        filled: true,
                        fillColor: scheme.surfaceContainerHighest,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: 'Send',
                    style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
                    onPressed: _send,
                    icon: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.text, required this.time, required this.fromMe});

  final String text;
  final String time;
  final bool fromMe;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = fromMe ? scheme.primary : scheme.surfaceContainerHighest;
    final fg = fromMe ? scheme.onPrimary : scheme.onSurface;

    return Align(
      alignment: fromMe ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.75),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 3),
          padding: const EdgeInsets.fromLTRB(14, 9, 14, 7),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(fromMe ? 18 : 4),
              bottomRight: Radius.circular(fromMe ? 4 : 18),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(text, style: TextStyle(color: fg, fontSize: 15)),
              const SizedBox(height: 2),
              Text(time, style: TextStyle(color: fg.withValues(alpha: 0.7), fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(color: scheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(18)),
        child: SizedBox(
          width: 28,
          height: 8,
          child: LinearProgressIndicator(borderRadius: BorderRadius.circular(4), minHeight: 4),
        ),
      ),
    );
  }
}
