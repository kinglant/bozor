import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../state/market_store.dart';
import '../widgets/common.dart';

Future<void> showFilterSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (_) => ChangeNotifierProvider.value(
      value: context.read<MarketStore>(),
      child: const _FilterSheet(),
    ),
  );
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet();

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late final MarketStore store = context.read<MarketStore>();
  late SortOption _sort = store.sort;
  late RangeValues _range = store.priceRange ?? RangeValues(0, store.maxPrice);
  late final Set<Condition> _conditions = {...store.conditions};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final max = store.maxPrice;
    final title = theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Filters', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 20),
          Text('Sort by', style: title),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in SortOption.values)
                ChoiceChip(label: Text(s.label), selected: _sort == s, onSelected: (_) => setState(() => _sort = s)),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Text('Price', style: title),
              const Spacer(),
              Text('${formatPrice(_range.start)} – ${formatPrice(_range.end)}'),
            ],
          ),
          RangeSlider(
            values: _range,
            min: 0,
            max: max,
            divisions: 50,
            onChanged: (v) => setState(() => _range = v),
          ),
          const SizedBox(height: 12),
          Text('Condition', style: title),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in Condition.values)
                FilterChip(
                  label: Text(c.label),
                  selected: _conditions.contains(c),
                  onSelected: (v) => setState(() => v ? _conditions.add(c) : _conditions.remove(c)),
                ),
            ],
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    store.resetFilters();
                    Navigator.pop(context);
                  },
                  child: const Text('Reset'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: () {
                    final fullRange = _range.start <= 0 && _range.end >= max;
                    store.applyFilters(sort: _sort, priceRange: fullRange ? null : _range, conditions: _conditions);
                    Navigator.pop(context);
                  },
                  child: const Text('Show results'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
