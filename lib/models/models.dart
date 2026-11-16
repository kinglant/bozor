import 'dart:convert';
import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';

enum Category {
  electronics('Electronics', Icons.devices_other_rounded),
  fashion('Fashion', Icons.checkroom_rounded),
  home('Home', Icons.chair_rounded),
  vehicles('Vehicles', Icons.pedal_bike_rounded),
  hobbies('Hobbies', Icons.sports_esports_rounded),
  kids('Kids', Icons.toys_rounded);

  const Category(this.label, this.icon);
  final String label;
  final IconData icon;
}

enum Condition {
  brandNew('New'),
  likeNew('Like new'),
  good('Good'),
  fair('Fair');

  const Condition(this.label);
  final String label;
}

enum SortOption {
  newest('Newest first'),
  priceLow('Price: low to high'),
  priceHigh('Price: high to low');

  const SortOption(this.label);
  final String label;
}

class Seller {
  const Seller({
    required this.id,
    required this.name,
    required this.avatar,
    required this.rating,
    required this.reviews,
    required this.memberSince,
    required this.responseTime,
  });

  final String id;
  final String name;
  final String avatar; // emoji avatar
  final double rating;
  final int reviews;
  final int memberSince;
  final String responseTime;
}

class Listing {
  const Listing({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.category,
    required this.condition,
    required this.location,
    required this.sellerId,
    required this.postedAt,
    required this.emoji,
    required this.palette,
    this.photos = const [],
    this.isMine = false,
    this.sold = false,
  });

  final String id;
  final String title;
  final String description;
  final double price;
  final Category category;
  final Condition condition;
  final String location;
  final String sellerId;
  final DateTime postedAt;

  /// Illustration used when the listing has no photos.
  final String emoji;
  final int palette;

  final List<Uint8List> photos;
  final bool isMine;
  final bool sold;

  Listing copyWith({bool? sold}) => Listing(
        id: id,
        title: title,
        description: description,
        price: price,
        category: category,
        condition: condition,
        location: location,
        sellerId: sellerId,
        postedAt: postedAt,
        emoji: emoji,
        palette: palette,
        photos: photos,
        isMine: isMine,
        sold: sold ?? this.sold,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'price': price,
        'category': category.name,
        'condition': condition.name,
        'location': location,
        'sellerId': sellerId,
        'postedAt': postedAt.toIso8601String(),
        'emoji': emoji,
        'palette': palette,
        'photos': photos.map(base64Encode).toList(),
        'isMine': isMine,
        'sold': sold,
      };

  factory Listing.fromJson(Map<String, dynamic> j) => Listing(
        id: j['id'] as String,
        title: j['title'] as String,
        description: j['description'] as String,
        price: (j['price'] as num).toDouble(),
        category: Category.values.byName(j['category'] as String),
        condition: Condition.values.byName(j['condition'] as String),
        location: j['location'] as String,
        sellerId: j['sellerId'] as String,
        postedAt: DateTime.parse(j['postedAt'] as String),
        emoji: j['emoji'] as String,
        palette: j['palette'] as int,
        photos: (j['photos'] as List).map((p) => base64Decode(p as String)).toList(),
        isMine: j['isMine'] as bool? ?? false,
        sold: j['sold'] as bool? ?? false,
      );
}

class Message {
  const Message({required this.text, required this.fromMe, required this.at});

  final String text;
  final bool fromMe;
  final DateTime at;

  Map<String, dynamic> toJson() => {'text': text, 'fromMe': fromMe, 'at': at.toIso8601String()};

  factory Message.fromJson(Map<String, dynamic> j) => Message(
        text: j['text'] as String,
        fromMe: j['fromMe'] as bool,
        at: DateTime.parse(j['at'] as String),
      );
}

class Conversation {
  Conversation({required this.listingId, List<Message>? messages, this.unread = 0})
      : messages = messages ?? [];

  final String listingId;
  final List<Message> messages;
  int unread;

  DateTime get lastAt => messages.isEmpty ? DateTime(2000) : messages.last.at;

  Map<String, dynamic> toJson() => {
        'listingId': listingId,
        'unread': unread,
        'messages': messages.map((m) => m.toJson()).toList(),
      };

  factory Conversation.fromJson(Map<String, dynamic> j) => Conversation(
        listingId: j['listingId'] as String,
        unread: j['unread'] as int? ?? 0,
        messages: (j['messages'] as List)
            .map((m) => Message.fromJson(m as Map<String, dynamic>))
            .toList(),
      );
}
