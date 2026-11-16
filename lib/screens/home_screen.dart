import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../state/market_store.dart';
import '../widgets/common.dart';
import '../widgets/listing_card.dart';
import 'filter_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final TextEditingController _search =
      TextEditingController(text: context.read<MarketStore>().query);

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<MarketStore>();
    final listings = store.visibleListings;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            titleSpacing: 16,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: scheme.primary, borderRadius: BorderRadius.circular(10)),
                  child: Icon(Icons.storefront_rounded, color: scheme.onPrimary, size: 20),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    'Bozor',
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: ActionChip(
                  avatar: Icon(Icons.location_on_rounded, size: 16, color: scheme.primary),
                  label: const Text('SF'),
                  tooltip: 'San Francisco, CA',
                  visualDensity: VisualDensity.compact,
                  onPressed: () {},
                ),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(64),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: SearchBar(
                        controller: _search,
                        hintText: 'Search phones, bikes, sofas…',
                        leading: const Icon(Icons.search_rounded),
                        elevation: const WidgetStatePropertyAll(0),
                        backgroundColor: WidgetStatePropertyAll(scheme.surfaceContainerHighest),
                        trailing: [
                          if (store.query.isNotEmpty)
                            IconButton(
                              tooltip: 'Clear search',
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () {
                                _search.clear();
                                store.setQuery('');
                              },
                            ),
                        ],
                        onChanged: store.setQuery,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Badge(
                      isLabelVisible: store.activeFilterCount > 0,
                      label: Text('${store.activeFilterCount}'),
                      child: IconButton.filledTonal(
                        tooltip: 'Filters',
                        iconSize: 24,
                        style: IconButton.styleFrom(minimumSize: const Size(52, 52)),
                        icon: const Icon(Icons.tune_rounded),
                        onPressed: () => showFilterSheet(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _CategoryChip(
                    label: 'All',
                    icon: Icons.apps_rounded,
                    selected: store.category == null,
                    onTap: () => store.setCategory(null),
                  ),
                  for (final c in Category.values)
                    _CategoryChip(
                      label: c.label,
                      icon: c.icon,
                      selected: store.category == c,
                      onTap: () => store.setCategory(store.category == c ? null : c),
                    ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      store.query.isEmpty && store.category == null ? 'Today\'s picks' : 'Results',
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('${listings.length} items', style: TextStyle(color: scheme.onSurfaceVariant)),
                  const Spacer(),
                  if (store.activeFilterCount > 0)
                    TextButton(onPressed: store.resetFilters, child: const Text('Clear filters')),
                ],
              ),
            ),
          ),
          if (listings.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                icon: Icons.search_off_rounded,
                title: 'No items found',
                message: 'Try a different search or remove some filters.',
                action: OutlinedButton(
                  onPressed: () {
                    _search.clear();
                    store
                      ..setQuery('')
                      ..setCategory(null)
                      ..resetFilters();
                  },
                  child: const Text('Reset search'),
                ),
              ),
            )
          else
            ListingSliverGrid(listings: listings, heroScope: 'home'),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.label, required this.icon, required this.selected, required this.onTap});

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        avatar: selected ? null : Icon(icon, size: 18),
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        showCheckmark: true,
      ),
    );
  }
}
