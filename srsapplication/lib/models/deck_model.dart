import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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

class DeckService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> deleteDeckHierarchically(String deckId) async {
    final User? user = _auth.currentUser;
    if (user == null) {
      throw Exception("Користувач не авторизований.");
    }

    List<String> decksToDelete = [];
    List<String> cardsToDelete = [];

    await _collectDecksAndCardsForDeletion(
      deckId,
      user.uid,
      decksToDelete,
      cardsToDelete,
    );

    if (decksToDelete.isEmpty) {
      print(
        "Не знайдено колод для видалення (можливо, лише початкова колода).",
      );
    }

    print("Колоди до видалення: $decksToDelete");
    print("Картки до видалення: $cardsToDelete");

    if (cardsToDelete.isNotEmpty) {
      WriteBatch cardBatch = _firestore.batch();
      for (String cardId in cardsToDelete) {
        cardBatch.delete(_firestore.collection('flashcards').doc(cardId));
      }
      try {
        await cardBatch.commit();
        print("Картки успішно видалено.");
      } catch (e) {
        print("Помилка під час видалення карток: $e");
      }
    }

    if (decksToDelete.isNotEmpty) {
      WriteBatch deckBatch = _firestore.batch();
      for (String id in decksToDelete) {
        deckBatch.delete(_firestore.collection('decks').doc(id));
      }
      try {
        await deckBatch.commit();
        print("Колоди успішно видалено.");
      } catch (e) {
        print("Помилка під час видалення колод: $e");
      }
    }
  }

  Future<void> _collectDecksAndCardsForDeletion(
    String currentDeckId,
    String userId,
    List<String> decksToDelete,
    List<String> cardsToDelete,
  ) async {
    if (!decksToDelete.contains(currentDeckId)) {
      decksToDelete.add(currentDeckId);
    }

    final cardsSnapshot =
        await _firestore
            .collection('flashcards')
            .where('userId', isEqualTo: userId)
            .where('deckId', isEqualTo: currentDeckId)
            .get();

    for (var doc in cardsSnapshot.docs) {
      if (!cardsToDelete.contains(doc.id)) {
        cardsToDelete.add(doc.id);
      }
    }

    final childrenDecksSnapshot =
        await _firestore
            .collection('decks')
            .where('userId', isEqualTo: userId)
            .where('parentId', isEqualTo: currentDeckId)
            .get();

    for (var doc in childrenDecksSnapshot.docs) {
      if (!decksToDelete.contains(doc.id)) {
        await _collectDecksAndCardsForDeletion(
          doc.id,
          userId,
          decksToDelete,
          cardsToDelete,
        );
      }
    }
  }
}
