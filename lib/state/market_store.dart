import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/sample_data.dart';
import '../models/models.dart';

/// App state: listings, search & filters, favorites, chats and theme.
/// Favorites, the user's own listings, chats and theme are persisted locally.
class MarketStore extends ChangeNotifier {
  MarketStore(this._prefs) {
    _load();
  }

  final SharedPreferences _prefs;
  final _random = Random();

  final List<Listing> _listings = sampleListings();
  final Set<String> _favorites = {};
  final Map<String, Conversation> _chats = {};

  // ── Search & filters ─────────────────────────────────────────
  String _query = '';
  Category? _category;
  SortOption _sort = SortOption.newest;
  RangeValues? _priceRange;
  final Set<Condition> _conditions = {};

  String get query => _query;
  Category? get category => _category;
  SortOption get sort => _sort;
  RangeValues? get priceRange => _priceRange;
  Set<Condition> get conditions => _conditions;
  ThemeMode themeMode = ThemeMode.system;

  int get activeFilterCount =>
      (_priceRange != null ? 1 : 0) + (_conditions.isNotEmpty ? 1 : 0) + (_sort != SortOption.newest ? 1 : 0);

  double get maxPrice => _listings.fold(0.0, (m, l) => max(m, l.price)).ceilToDouble();

  List<Listing> get visibleListings {
    final q = _query.trim().toLowerCase();
    final result = _listings.where((l) {
      if (l.sold && !l.isMine) return false;
      if (_category != null && l.category != _category) return false;
      if (_conditions.isNotEmpty && !_conditions.contains(l.condition)) return false;
      final range = _priceRange;
      if (range != null && (l.price < range.start || l.price > range.end)) return false;
      if (q.isNotEmpty &&
          !l.title.toLowerCase().contains(q) &&
          !l.description.toLowerCase().contains(q) &&
          !l.location.toLowerCase().contains(q)) {
        return false;
      }
      return true;
    }).toList();

    switch (_sort) {
      case SortOption.newest:
        result.sort((a, b) => b.postedAt.compareTo(a.postedAt));
      case SortOption.priceLow:
        result.sort((a, b) => a.price.compareTo(b.price));
      case SortOption.priceHigh:
        result.sort((a, b) => b.price.compareTo(a.price));
    }
    return result;
  }

  void setQuery(String value) {
    _query = value;
    notifyListeners();
  }

  void setCategory(Category? value) {
    _category = value;
    notifyListeners();
  }

  void applyFilters({required SortOption sort, RangeValues? priceRange, required Set<Condition> conditions}) {
    _sort = sort;
    _priceRange = priceRange;
    _conditions
      ..clear()
      ..addAll(conditions);
    notifyListeners();
  }

  void resetFilters() => applyFilters(sort: SortOption.newest, priceRange: null, conditions: {});

  // ── Listings ─────────────────────────────────────────────────
  Listing? listingById(String id) {
    for (final l in _listings) {
      if (l.id == id) return l;
    }
    return null;
  }

  List<Listing> get myListings =>
      _listings.where((l) => l.isMine).toList()..sort((a, b) => b.postedAt.compareTo(a.postedAt));

  List<Listing> moreFromSeller(Listing listing) =>
      _listings.where((l) => l.sellerId == listing.sellerId && l.id != listing.id && !l.sold).take(6).toList();

  void addListing({
    required String title,
    required String description,
    required double price,
    required Category category,
    required Condition condition,
    required String location,
    required List<dynamic> photos,
  }) {
    const emojiByCategory = {
      Category.electronics: '📦',
      Category.fashion: '👕',
      Category.home: '🏠',
      Category.vehicles: '🚗',
      Category.hobbies: '🎯',
      Category.kids: '🪀',
    };
    _listings.add(Listing(
      id: 'me_${DateTime.now().microsecondsSinceEpoch}',
      title: title,
      description: description,
      price: price,
      category: category,
      condition: condition,
      location: location,
      sellerId: me.id,
      postedAt: DateTime.now(),
      emoji: emojiByCategory[category]!,
      palette: _random.nextInt(8),
      photos: photos.cast(),
      isMine: true,
    ));
    _saveMine();
    notifyListeners();
  }

  void toggleSold(String id) {
    final i = _listings.indexWhere((l) => l.id == id);
    if (i == -1) return;
    _listings[i] = _listings[i].copyWith(sold: !_listings[i].sold);
    _saveMine();
    notifyListeners();
  }

  void deleteListing(String id) {
    _listings.removeWhere((l) => l.id == id && l.isMine);
    _favorites.remove(id);
    _chats.remove(id);
    _saveMine();
    _saveFavorites();
    _saveChats();
    notifyListeners();
  }

  // ── Favorites ────────────────────────────────────────────────
  bool isFavorite(String id) => _favorites.contains(id);

  List<Listing> get favoriteListings =>
      _favorites.map(listingById).whereType<Listing>().toList();

  void toggleFavorite(String id) {
    _favorites.contains(id) ? _favorites.remove(id) : _favorites.add(id);
    _saveFavorites();
    notifyListeners();
  }

  // ── Chats ────────────────────────────────────────────────────
  List<Conversation> get conversations => _chats.values
      .where((c) => c.messages.isNotEmpty && listingById(c.listingId) != null)
      .toList()
    ..sort((a, b) => b.lastAt.compareTo(a.lastAt));

  int get unreadCount => _chats.values.fold(0, (sum, c) => sum + c.unread);

  Conversation chatFor(String listingId) =>
      _chats.putIfAbsent(listingId, () => Conversation(listingId: listingId));

  void markRead(String listingId) {
    final chat = _chats[listingId];
    if (chat == null || chat.unread == 0) return;
    chat.unread = 0;
    _saveChats();
    notifyListeners();
  }

  /// Whether the seller is "typing" a reply in a given chat.
  final Set<String> typing = {};

  void sendMessage(String listingId, String text) {
    final listing = listingById(listingId);
    if (listing == null || text.trim().isEmpty) return;
    chatFor(listingId).messages.add(Message(text: text.trim(), fromMe: true, at: DateTime.now()));
    _saveChats();
    notifyListeners();

    if (listing.isMine) return; // nobody to answer on your own listing

    // Demo: the seller replies after a short delay.
    typing.add(listingId);
    Timer(Duration(milliseconds: 1200 + _random.nextInt(1200)), () {
      typing.remove(listingId);
      chatFor(listingId).messages.add(Message(text: _autoReply(text, listing), fromMe: false, at: DateTime.now()));
      _saveChats();
      notifyListeners();
    });
  }

  String _autoReply(String text, Listing listing) {
    final t = text.toLowerCase();
    final price = listing.price.round();
    if (t.contains('available')) return 'Yes, it\'s still available! When would you like to see it?';
    if (t.contains('lower') || t.contains('price') || t.contains('\$') || t.contains('offer')) {
      return 'I could do \$${(price * 0.9).round()} if you can pick it up soon.';
    }
    if (t.contains('meet') || t.contains('where') || t.contains('pick')) {
      return 'We can meet in ${listing.location.split(',').first}. Does tomorrow evening work for you?';
    }
    if (t.contains('photo') || t.contains('picture')) return 'Sure, I\'ll send a few more photos in a minute 📸';
    return 'Thanks for your message! Let me know if you have any questions about it 🙂';
  }

  // ── Theme ────────────────────────────────────────────────────
  void setThemeMode(ThemeMode mode) {
    themeMode = mode;
    _prefs.setString('theme', mode.name);
    notifyListeners();
  }

  // ── Persistence ──────────────────────────────────────────────
  void _load() {
    _favorites.addAll(_prefs.getStringList('favorites') ?? const ['l2', 'l6']);

    final mine = _prefs.getString('my_listings');
    if (mine != null) {
      for (final j in jsonDecode(mine) as List) {
        _listings.add(Listing.fromJson(j as Map<String, dynamic>));
      }
    }

    final chats = _prefs.getString('chats');
    final list = chats != null
        ? (jsonDecode(chats) as List).map((j) => Conversation.fromJson(j as Map<String, dynamic>))
        : sampleConversations();
    for (final c in list) {
      _chats[c.listingId] = c;
    }

    final theme = _prefs.getString('theme');
    if (theme != null) themeMode = ThemeMode.values.byName(theme);
  }

  void _saveFavorites() => _prefs.setStringList('favorites', _favorites.toList());

  void _saveMine() => _prefs.setString(
        'my_listings',
        jsonEncode(_listings.where((l) => l.isMine).map((l) => l.toJson()).toList()),
      );

  void _saveChats() => _prefs.setString(
        'chats',
        jsonEncode(_chats.values.where((c) => c.messages.isNotEmpty).map((c) => c.toJson()).toList()),
      );
}
