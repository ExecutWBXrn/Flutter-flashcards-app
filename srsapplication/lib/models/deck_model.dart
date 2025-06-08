import 'package:cloud_firestore/cloud_firestore.dart';

class Deck {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final Timestamp createdAt;
  final Timestamp? updatedAt;
  final String? languageFrom;
  final String? languageTo;
  final int cardCount;
  final String? parentId;
  final int depth;

  bool get isTopLevel => parentId == null;

  Deck({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    required this.createdAt,
    this.updatedAt,
    this.languageFrom,
    this.languageTo,
    this.cardCount = 0,
    this.parentId,
    this.depth = 0,
  });

  factory Deck.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    return Deck(
      id: snapshot.id,
      userId: data?['userId'] ?? '',
      name: data?['name'] ?? 'Без назви',
      description: data?['description'],
      createdAt: data?['createdAt'] ?? Timestamp.now(),
      updatedAt: data?['updatedAt'] as Timestamp?,
      languageFrom: data?['languageFrom'],
      languageTo: data?['languageTo'],
      cardCount: data?['cardCount'] ?? 0,
      parentId: data?['parentId'],
      depth: data?['depth'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'name': name,
      if (description != null) 'description': description,
      'createdAt': createdAt,
      if (updatedAt != null) 'updatedAt': updatedAt,
      if (languageFrom != null) 'languageFrom': languageFrom,
      if (languageTo != null) 'languageTo': languageTo,
      'cardCount': cardCount,
      if (parentId != null) 'parentId': parentId,
      'depth': depth,
    };
  }

  Deck copyWith({
    String? id,
    String? name,
    String? description,
    String? userId,
    Timestamp? createdAt,
    Timestamp? updatedAt,
    int? cardCount,
  }) {
    return Deck(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      cardCount: cardCount ?? this.cardCount,
    );
  }
}
