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
  final int cardCount;
  final String? parentId;
  final List<String> ancestorIds;

  bool get isTopLevel => parentId == null;

  Deck({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    required this.createdAt,
    this.updatedAt,
    this.cardCount = 0,
    this.parentId,
    required this.ancestorIds,
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
      cardCount: data?['cardCount'] ?? 0,
      parentId: data?['parentId'],
      ancestorIds: List<String>.from(
        data?['ancestorIds'] as List<dynamic>? ?? [],
      ),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'name': name,
      'ancestorIds': ancestorIds,
      if (description != null) 'description': description,
      'createdAt': createdAt,
      if (updatedAt != null) 'updatedAt': updatedAt,
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
    List<String>? ancestorIds,
  }) {
    return Deck(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      cardCount: cardCount ?? this.cardCount,
      ancestorIds: ancestorIds ?? this.ancestorIds,
    );
  }
}

class DeckService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  int counter = 0;

  Future<void> deleteCardCount(List<String> deckId) async {
    try {
      final User? user = _auth.currentUser;
      WriteBatch wBatch = _firestore.batch();
      QuerySnapshot qsnap =
          await _firestore
              .collection("decks")
              .where("userId", isEqualTo: user?.uid)
              .where(FieldPath.documentId, whereIn: deckId)
              .get();
      for (DocumentSnapshot snp in qsnap.docs) {
        wBatch.update(snp.reference, {
          "cardCount": FieldValue.increment(-counter),
        });
      }
      await wBatch.commit();
    } catch (e) {
      print("Помилка оновлення лічильника карток у колоді: $e");
    }
  }

  Future<void> deleteDeckHierarchically(Set<Deck> deckId) async {
    final User? user = _auth.currentUser;
    if (user == null) {
      throw Exception("Користувач не авторизований.");
    }

    List<String> decksToDelete = [];
    List<String> cardsToDelete = [];
    List<String> anyTopLevelDeck = deckId.first.ancestorIds;

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
        deleteCardCount(anyTopLevelDeck);
        print("Колоди успішно видалено.");
      } catch (e) {
        print("Помилка під час видалення колод: $e");
      }
    }
  }

  Future<void> _collectDecksAndCardsForDeletion(
    Set<Deck> rootDecks,
    String userId,
    List<String> decksToDeleteCollector,
    List<String> cardsToDeleteCollector,
  ) async {
    if (rootDecks.isEmpty) {
      print("Набір початкових колод порожній.");
      return;
    }
    for (Deck deck in rootDecks) {
      if (!decksToDeleteCollector.contains(deck.id)) {
        decksToDeleteCollector.add(deck.id);
        counter += deck.cardCount;
      }
    }

    List<String> rootDeckIds = rootDecks.map((deck) => deck.id).toList();

    const int arrayContainsAnyLimit = 30;
    List<Future<QuerySnapshot<Map<String, dynamic>>>> childrenDeckFutures = [];

    for (int i = 0; i < rootDeckIds.length; i += arrayContainsAnyLimit) {
      List<String> sublist = rootDeckIds.sublist(
        i,
        i + arrayContainsAnyLimit > rootDeckIds.length
            ? rootDeckIds.length
            : i + arrayContainsAnyLimit,
      );
      if (sublist.isNotEmpty) {
        childrenDeckFutures.add(
          _firestore
              .collection('decks')
              .where('userId', isEqualTo: userId)
              .where('ancestorIds', arrayContainsAny: sublist)
              .get(),
        );
      }
    }

    final List<QuerySnapshot<Map<String, dynamic>>> childrenDeckSnapshots =
        await Future.wait(childrenDeckFutures);

    for (final snapshot in childrenDeckSnapshots) {
      for (var doc in snapshot.docs) {
        if (!decksToDeleteCollector.contains(doc.id)) {
          decksToDeleteCollector.add(doc.id);
        }
      }
    }

    if (decksToDeleteCollector.isEmpty) {
      print(
        "Немає колод для видалення (початкових або дочірніх), картки не шукаємо.",
      );
      return;
    }

    const int whereInLimit = 30;
    List<Future<QuerySnapshot<Map<String, dynamic>>>> cardsFutures = [];

    List<String> uniqueDecksToDelete = decksToDeleteCollector.toSet().toList();

    for (int i = 0; i < uniqueDecksToDelete.length; i += whereInLimit) {
      List<String> sublist = uniqueDecksToDelete.sublist(
        i,
        i + whereInLimit > uniqueDecksToDelete.length
            ? uniqueDecksToDelete.length
            : i + whereInLimit,
      );
      if (sublist.isNotEmpty) {
        cardsFutures.add(
          _firestore
              .collection('flashcards')
              .where('userId', isEqualTo: userId)
              .where('deckId', whereIn: sublist)
              .get(),
        );
      }
    }

    final List<QuerySnapshot<Map<String, dynamic>>> cardsSnapshots =
        await Future.wait(cardsFutures);

    Set<String> cardsToDeleteSet = cardsToDeleteCollector.toSet();
    for (final snapshot in cardsSnapshots) {
      for (var doc in snapshot.docs) {
        cardsToDeleteSet.add(doc.id);
      }
    }
    cardsToDeleteCollector.clear();
    cardsToDeleteCollector.addAll(cardsToDeleteSet);

    print(
      "Зібрано ${decksToDeleteCollector.length} колод та ${cardsToDeleteCollector.length} карток для видалення.",
    );
  }
}
