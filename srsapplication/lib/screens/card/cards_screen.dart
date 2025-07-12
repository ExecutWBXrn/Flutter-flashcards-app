import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:srsapplication/models/deck_model.dart';
import 'package:srsapplication/models/card_model.dart';
import 'package:srsapplication/screens/deck/deck_create.dart';
import 'package:srsapplication/screens/card/card_create.dart';
import 'package:srsapplication/screens/games/game.dart';
import 'package:srsapplication/screens/deck/deck_screen.dart';
import 'package:srsapplication/func/card_deck/func.dart';
import '../../func/messages/snackbars.dart';

class CardListScreen extends StatefulWidget {
  final String parentId;
  final String? parentDeckName;
  final bool? toFrom;
  final List<String>? parentDeckIds;

  const CardListScreen({
    super.key,
    required this.parentId,
    required this.parentDeckIds,
    this.parentDeckName,
    this.toFrom,
  });

  @override
  State<StatefulWidget> createState() {
    return _cardListScreenState();
  }
}

class _cardListScreenState extends State<CardListScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Set<Deck> _choosenDeck = {};
  final Set<FlashCard> _choosenCard = {};
  bool? _currentFrom;

  @override
  void initState() {
    super.initState();
    _currentFrom = widget.toFrom ?? true;
    _initializeAsyncData();
    print(
      "[CardListScreen initState] deckId: ${widget.parentId}, deckName: ${widget.parentDeckName}",
    );
  }

  Future<void> _initializeAsyncData() async {
    await _loadData();
    if (_currentFrom == true) {
      await _saveData(true);
    }
  }

  Future<void> _saveData(bool ToFrom) async {
    final SharedPreferences pref = await SharedPreferences.getInstance();
    await pref.setBool("toFrom", ToFrom);
  }

  Future<void> _loadData() async {
    final SharedPreferences pref = await SharedPreferences.getInstance();
    setState(() {
      _currentFrom = pref.getBool("toFrom");
      _currentFrom ??= true;
    });
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
      _choosenDeck.clear();
      _choosenCard.clear();
    });
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => CreateEditDeckScreen(
              parentDeckId: widget.parentId,
              ancestorDeckIds: widget.parentDeckIds,
            ),
      ),
    );
    print("Перехід на екран створення колоди");
  }

  void _navigateToDeckDetailScreen(Deck deck) {
    setState(() {
      _choosenDeck.clear();
      _choosenCard.clear();
    });
    List<String>? _parentAndCurrentIds = widget.parentDeckIds;
    _parentAndCurrentIds?.add(deck.id);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => CardListScreen(
              parentId: deck.id,
              parentDeckName: deck.name,
              parentDeckIds: _parentAndCurrentIds,
            ),
      ),
    );
  }

  void _navigateToCreateCardScreen() {
    setState(() {
      _choosenDeck.clear();
      _choosenCard.clear();
    });
    if (widget.parentId == null) {
      if (mounted) {
        showErrorSnackbar(
          context,
          "First select or create a deck to add a card",
        );
      }

      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateEditCardScreen(deckId: widget.parentId),
      ),
    );
  }

  Future<void> _addDecrement(String deckId) async {
    try {
      final deckDocRef = _firestore.collection('decks').doc(deckId);
      await deckDocRef.update({'cardCount': FieldValue.increment(-1)});
      try {
        DocumentSnapshot snap = await deckDocRef.get();
        if (snap.exists) {
          String? parentId = (snap.data() as Map<String, dynamic>)['parentId'];
          if (parentId != null) {
            _addDecrement(parentId);
          }
        }
      } catch (e) {
        print("Помилка оновлення лічильника карток у колоді: $e");
      }
    } catch (e) {
      print("Помилка оновлення лічильника карток у колоді: $e");
    }
  }

  Future<void> deleteCardOnly(String cardId) async {
    try {
      await FirebaseFirestore.instance
          .collection('flashcards')
          .doc(cardId)
          .delete();
      print('FlashCard document $cardId deleted.');
    } catch (e) {
      print('Error deleting card document $cardId: $e');
    }
    _addDecrement(widget.parentId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(children: [Text("Flashcards")]),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          if (_choosenDeck.isNotEmpty || _choosenCard.isNotEmpty)
            PopupMenuButton(
              icon: Icon(Icons.more_vert),
              itemBuilder:
                  (BuildContext context) => <PopupMenuEntry<MenuAction>>[
                    if ((_choosenDeck.length == 1 && _choosenCard.isEmpty) ||
                        (_choosenCard.length == 1 && _choosenDeck.isEmpty))
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
              onSelected: (MenuAction action) async {
                if (action == MenuAction.delete) {
                  if (_choosenDeck.isNotEmpty) {
                    await showAlertDeleteDeckDialog(context, _choosenDeck);
                    setState(() {
                      _choosenDeck.clear();
                    });
                  }
                  if (_choosenCard.isNotEmpty) {
                    for (FlashCard c in _choosenCard) {
                      await deleteCardOnly(c.cardId);
                    }
                    setState(() {
                      _choosenCard.clear();
                    });
                  }
                } else if (action == MenuAction.edit) {
                  _choosenDeck.isNotEmpty
                      ? Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => CreateEditDeckScreen(
                                deckToEdit: _choosenDeck.first,
                              ),
                        ),
                      )
                      : Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => CreateEditCardScreen(
                                existingCard: _choosenCard.first,
                                deckId: _choosenCard.first.deckId,
                              ),
                        ),
                      );
                }
              },
            )
          else
            Padding(
              padding: EdgeInsets.only(right: 15),
              child: Row(
                children: [
                  Text(_currentFrom ?? true ? "F" : "B"),
                  IconButton(
                    onPressed: () {
                      bool currentValue = _currentFrom ?? true;
                      setState(() {
                        _currentFrom = !currentValue;
                      });
                      _saveData(_currentFrom!);
                    },
                    icon: Icon(Icons.compare_arrows),
                  ),
                  Text(_currentFrom ?? true ? "B" : "F"),
                ],
              ),
            ),
        ],
      ),
      body: CustomScrollView(
        slivers: <Widget>[
          StreamBuilder<List<Deck>>(
            stream: getUserDecksStream(widget.parentId),
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
                          isChoosenDeck(deck.id, _choosenDeck)
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
                                "Cards: ${deck.cardCount}",
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ),
                          ],
                        ),
                        trailing: FutureBuilder(
                          future: getRepeatDecks(deck.id),
                          builder: (
                            BuildContext context,
                            AsyncSnapshot<bool> snapshot,
                          ) {
                            bool currentPlayIconColor;

                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              currentPlayIconColor = snapshot.data ?? false;
                            } else if (snapshot.hasError) {
                              currentPlayIconColor = false;
                            } else if (snapshot.hasData) {
                              currentPlayIconColor = snapshot.data!;
                            } else {
                              currentPlayIconColor = false;
                            }

                            return PopupMenuButton<GameAction>(
                              icon: Icon(
                                Icons.play_arrow,
                                size: 40,
                                color:
                                    currentPlayIconColor
                                        ? Colors.red
                                        : Colors.green,
                              ),
                              itemBuilder:
                                  (
                                    BuildContext context,
                                  ) => <PopupMenuEntry<GameAction>>[
                                    const PopupMenuItem<GameAction>(
                                      value: GameAction.learn,
                                      child: ListTile(
                                        leading: Icon(Icons.task_alt),
                                        title: Text('Learn it'),
                                      ),
                                    ),
                                    const PopupMenuItem<GameAction>(
                                      value: GameAction.repeat,
                                      child: ListTile(
                                        leading: Icon(
                                          Icons.assignment_outlined,
                                        ),
                                        title: Text('Write all'),
                                      ),
                                    ),
                                    const PopupMenuItem<GameAction>(
                                      value: GameAction.repeat2,
                                      child: ListTile(
                                        leading: Icon(
                                          Icons.assignment_outlined,
                                        ),
                                        title: Text('Write first level cards'),
                                      ),
                                    ),
                                  ],
                              onSelected: (GameAction action) {
                                if (deck.cardCount > 0) {
                                  if (action == GameAction.learn) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => GamePage(
                                              deckId: deck.id,
                                              gameMode: 0,
                                              toFrom: _currentFrom ?? true,
                                            ),
                                      ),
                                    );
                                  } else if (action == GameAction.repeat) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => GamePage(
                                              deckId: deck.id,
                                              gameMode: 1,
                                              toFrom: _currentFrom ?? true,
                                            ),
                                      ),
                                    );
                                  } else if (action == GameAction.repeat2) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => GamePage(
                                              deckId: deck.id,
                                              gameMode: 2,
                                              toFrom: _currentFrom ?? true,
                                            ),
                                      ),
                                    );
                                  }
                                } else {
                                  if (mounted) {
                                    showErrorSnackbar(
                                      context,
                                      "Add cards to the deck to study them",
                                    );
                                  }
                                }
                              },
                            );
                          },
                        ),
                        onLongPress: () {
                          setState(() {
                            if (isChoosenDeck(deck.id, _choosenDeck)) {
                              _choosenDeck.removeWhere((e) => e.id == deck.id);
                            } else {
                              _choosenDeck.add(deck);
                            }
                          });
                        },
                        onTap: () {
                          if (_choosenDeck.isEmpty && _choosenCard.isEmpty) {
                            _navigateToDeckDetailScreen(deck);
                          } else {
                            setState(() {
                              if (isChoosenDeck(deck.id, _choosenDeck)) {
                                _choosenDeck.removeWhere(
                                  (e) => e.id == deck.id,
                                );
                              } else {
                                _choosenDeck.add(deck);
                              }
                            });
                          }
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
                      child: Text('Error loading cards: ${cardSnapshot.error}'),
                    ),
                  );
                }
                if (!cardSnapshot.hasData || cardSnapshot.data!.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('This deck has no cards yet'),
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
                          _choosenCard
                                  .where((e) => e.cardId == card.cardId)
                                  .isNotEmpty
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
                          "${((card.proficiencyLevel / 6) * 100).round()}%",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 10),
                        ),
                        trailing: Text(
                          card.wordTo,
                          style: TextStyle(fontSize: 20),
                        ),
                        onLongPress: () {
                          setState(() {
                            if (_choosenCard
                                .where((e) => e.cardId == card.cardId)
                                .isEmpty) {
                              _choosenCard.add(card);
                            } else {
                              _choosenCard.remove(card);
                            }
                          });
                        },
                        onTap:
                            () => {
                              if (_choosenCard.isEmpty && _choosenDeck.isEmpty)
                                {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => CreateEditCardScreen(
                                            existingCard: card,
                                            deckId: card.deckId,
                                          ),
                                    ),
                                  ),
                                }
                              else
                                {
                                  setState(() {
                                    if (_choosenCard
                                        .where((e) => e.cardId == card.cardId)
                                        .isEmpty) {
                                      _choosenCard.add(card);
                                    } else {
                                      _choosenCard.removeWhere(
                                        (e) => e.cardId == card.cardId,
                                      );
                                    }
                                  }),
                                },
                            },
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
              'Create deck',
              _navigateToCreateDeckScreen,
            ),
            _buildBottomNavItem(
              Icons.add,
              'Add card',
              _navigateToCreateCardScreen,
            ),
          ],
        ),
      ),
    );
  }
}
