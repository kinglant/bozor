import 'package:bozor/main.dart';
import 'package:bozor/state/market_store.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<MarketStore> _store() async {
  SharedPreferences.setMockInitialValues({});
  return MarketStore(await SharedPreferences.getInstance());
}

void main() {
  test('search, category and price filters narrow the results', () async {
    final store = await _store();
    final all = store.visibleListings.length;

    store.setQuery('iphone');
    expect(store.visibleListings.map((l) => l.id), ['l1']);

    store.setQuery('');
    store.applyFilters(sort: store.sort, priceRange: const RangeValues(0, 100), conditions: {});
    expect(store.visibleListings.every((l) => l.price <= 100), isTrue);
    expect(store.visibleListings.length, lessThan(all));
  });

  test('favorites toggle and persist', () async {
    final store = await _store();
    final before = store.isFavorite('l4');
    store.toggleFavorite('l4');
    expect(store.isFavorite('l4'), !before);

    final reloaded = MarketStore(await SharedPreferences.getInstance());
    expect(reloaded.isFavorite('l4'), !before);
  });

  testWidgets('home screen shows listings and opens a listing', (tester) async {
    final store = await _store();
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(ChangeNotifierProvider.value(value: store, child: const BozorApp()));
    await tester.pumpAndSettle();

    expect(find.text('Bozor'), findsOneWidget);
    expect(find.text("Today's picks"), findsOneWidget);

    await tester.tap(find.text('iPhone 16 Pro, 256GB, Desert Titanium'));
    await tester.pumpAndSettle();
    expect(find.text('Description'), findsOneWidget);
    expect(find.text('Message'), findsOneWidget);
  });
}
