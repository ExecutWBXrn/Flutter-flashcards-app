import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:srsapplication/models/deck_model.dart';
import 'package:srsapplication/models/card_model.dart';
import 'package:srsapplication/screens/deck/deck_create.dart';
import 'package:srsapplication/screens/card/card_create.dart';

import '../deck/deck_screen.dart';

class CardListScreen extends StatefulWidget {
  final String parentId;
  final String? parentDeckName;

  const CardListScreen({
    super.key,
    required this.parentId,
    this.parentDeckName,
  });

  @override
  State<StatefulWidget> createState() {
    return _cardListScreenState();
  }
}

class _cardListScreenState extends State<CardListScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Deck? _choosenDeck;
  FlashCard? _choosenCard;

  @override
  void initState() {
    super.initState();
    print(
      "[CardListScreen initState] deckId: ${widget.parentId}, deckName: ${widget.parentDeckName}",
    );
  }

  Stream<List<Deck>> _getUserDecksStream({String order = 'createdAt'}) {
    final User? user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    Query query = _firestore
        .collection('decks')
        .where('userId', isEqualTo: user.uid);

    if (widget.parentId == null) {
      query = query.where('parentId', isNull: true);
    } else {
      query = query.where('parentId', isEqualTo: widget.parentId);
    }

    return query
        .orderBy(order, descending: true)
        .withConverter<Deck>(
          fromFirestore: Deck.fromFirestore,
          toFirestore: (Deck deck, _) => deck.toFirestore(),
        )
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Stream<List<FlashCard>> _getCardsForCurrentDeckStream({
    String order = 'createdAt',
  }) {
    final User? user = _auth.currentUser;
    if (user == null || widget.parentId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('flashcards')
        .where('userId', isEqualTo: user.uid)
        .where('deckId', isEqualTo: widget.parentId)
        .orderBy(order, descending: false)
        .withConverter<FlashCard>(
          fromFirestore: FlashCard.fromFirestore,
          toFirestore: (FlashCard card, _) => card.toFirestore(),
        )
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Widget _buildBottomNavItem(
    IconData icon,
    String label,
    VoidCallback onPressed,
  ) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10.0),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10.0),
        splashColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        highlightColor: Theme.of(context).colorScheme.primary.withOpacity(0.05),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToCreateDeckScreen() {
    setState(() {
      _choosenDeck = null;
      _choosenCard = null;
    });
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => CreateEditDeckScreen(parentDeckId: widget.parentId),
      ),
    );
    print("Перехід на екран створення колоди");
  }

  void _navigateToDeckDetailScreen(Deck deck) {
    setState(() {
      _choosenDeck = null;
      _choosenCard = null;
    });
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) =>
                CardListScreen(parentId: deck.id, parentDeckName: deck.name),
      ),
    );
  }

  void _handleCardTap(FlashCard card) {
    setState(() {
      _choosenDeck = null;
      _choosenCard = null;
    });
    // Наприклад, відкрити екран перегляду/редагування картки
    print("Натиснуто картку: ${card.wordFrom}");
    // Navigator.push(context, MaterialPageRoute(builder: (context) => ViewEditCardScreen(card: card)));
  }

  void _navigateToCreateCardScreen() {
    setState(() {
      _choosenDeck = null;
      _choosenCard = null;
    });
    if (widget.parentId == null) {
      _showErrorSnackbar(
        "Спочатку виберіть або створіть колоду для додавання картки.",
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateEditCardScreen(deckId: widget.parentId),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  Future<void> deleteDeckOnly(String deckId) async {
    setState(() {
      _choosenDeck = null;
    });
    try {
      await FirebaseFirestore.instance.collection('decks').doc(deckId).delete();
      print('Deck document $deckId deleted.');
    } catch (e) {
      print('Error deleting deck document $deckId: $e');
    }
  }

  Future<void> deleteCardOnly(String cardId) async {
    setState(() {
      _choosenCard = null;
    });
    try {
      await FirebaseFirestore.instance
          .collection('flashcards')
          .doc(cardId)
          .delete();
      print('FlashCard document $cardId deleted.');
    } catch (e) {
      print('Error deleting card document $cardId: $e');
    }
    try {
      final deckDocRef = _firestore.collection('decks').doc(widget.parentId);
      print(widget.parentId);
      await deckDocRef.update({'cardCount': FieldValue.increment(-1)});
    } catch (e) {
      print("Помилка оновлення лічильника карток у колоді: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Картки'),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          if (_choosenDeck != null || _choosenCard != null)
            PopupMenuButton(
              icon: Icon(Icons.more_vert),
              itemBuilder:
                  (BuildContext context) => <PopupMenuEntry<MenuAction>>[
                    const PopupMenuItem<MenuAction>(
                      value: MenuAction.edit,
                      child: ListTile(
                        leading: Icon(Icons.edit),
                        title: Text('Edit'),
                      ),
                    ),
                    const PopupMenuItem<MenuAction>(
                      value: MenuAction.delete,
                      child: ListTile(
                        leading: Icon(Icons.delete_outline),
                        title: Text('Delete'),
                      ),
                    ),
                  ],
              onSelected: (MenuAction action) {
                if (action == MenuAction.delete) {
                  _choosenDeck != null
                      ? deleteDeckOnly(_choosenDeck!.id)
                      : deleteCardOnly(_choosenCard!.cardId);
                } else if (action == MenuAction.edit) {
                  _choosenDeck != null
                      ? Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => CreateEditDeckScreen(
                                deckToEdit: _choosenDeck,
                              ),
                        ),
                      )
                      : Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => CreateEditCardScreen(
                                existingCard: _choosenCard,
                                deckId: _choosenCard!.deckId,
                              ),
                        ),
                      );
                }
              },
            ),
        ],
      ),
      body: CustomScrollView(
        slivers: <Widget>[
          StreamBuilder<List<Deck>>(
            stream: _getUserDecksStream(),
            builder: (context, snapshot) {
              try {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverToBoxAdapter(child: SizedBox.shrink());
                }
                if (snapshot.hasError) {
                  print(
                    "Помилка завантаження дочірніх колод: ${snapshot.error}",
                  );
                  return const SliverToBoxAdapter(child: SizedBox.shrink());
                }

                final decks = snapshot.data!;

                return SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final deck = decks[index];
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                      color:
                          _choosenDeck?.id == deck.id
                              ? Theme.of(context).primaryColor
                              : null,
                      child: ListTile(
                        title: Text(
                          deck.name,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (deck.description != null &&
                                deck.description!.isNotEmpty)
                              Padding(
                                padding: EdgeInsets.only(top: 4),
                                child: Text(deck.description!),
                              ),
                            Padding(
                              padding: EdgeInsets.only(top: 4),
                              child: Text(
                                "Карток: ${deck.cardCount}",
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          onPressed: () {},
                          icon: Icon(
                            Icons.play_arrow,
                            size: 40,
                            color: Colors.green,
                          ),
                        ),
                        onLongPress: () {
                          setState(() {
                            _choosenDeck = deck;
                          });
                        },
                        onTap: () {
                          _navigateToDeckDetailScreen(deck);
                        },
                      ),
                    );
                  }, childCount: decks.length),
                );
              } catch (e) {
                print("Не вдалось завантажити колоди: ${e}");
                return Text("");
              }
            },
          ),
          if (widget.parentId != null) ...[
            StreamBuilder<List<FlashCard>>(
              stream: _getCardsForCurrentDeckStream(),
              builder: (context, cardSnapshot) {
                if (cardSnapshot.connectionState == ConnectionState.waiting) {
                  return const SliverToBoxAdapter(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (cardSnapshot.hasError) {
                  return SliverToBoxAdapter(
                    child: Center(
                      child: Text(
                        'Помилка завантаження карток: ${cardSnapshot.error}',
                      ),
                    ),
                  );
                }
                if (!cardSnapshot.hasData || cardSnapshot.data!.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('У цій колоді ще немає карток.'),
                      ),
                    ),
                  );
                }
                final cards = cardSnapshot.data!;
                return SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final card = cards[index];
                    return Card(
                      color:
                          _choosenCard?.cardId == card.cardId
                              ? Theme.of(context).primaryColor
                              : null,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(0),
                      ),
                      margin: const EdgeInsets.symmetric(
                        horizontal: 0,
                        vertical: 0,
                      ),
                      child: ListTile(
                        leading: Text(
                          card.wordFrom,
                          style: TextStyle(fontSize: 20),
                        ),
                        title: Text(
                          "|",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 20),
                        ),
                        trailing: Text(
                          card.wordTo,
                          style: TextStyle(fontSize: 20),
                        ),
                        onLongPress: () {
                          setState(() {
                            _choosenCard = card;
                          });
                        },
                        onTap: () => _handleCardTap(card),
                      ),
                    );
                  }, childCount: cards.length),
                );
              },
            ),
          ],
          const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        color: Theme.of(context).primaryColor,
        height: 175,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildBottomNavItem(
              Icons.create_new_folder,
              'Створити колоду',
              _navigateToCreateDeckScreen,
            ),
            _buildBottomNavItem(
              Icons.add,
              'Додати картку',
              _navigateToCreateCardScreen,
            ),
          ],
        ),
      ),
    );
  }
}
