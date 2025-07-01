import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:srsapplication/models/card_model.dart';
import '../../func/messages/snackbars.dart';
import 'package:flutter/services.dart';

import '../../models/deck_model.dart';

class GamePage extends StatefulWidget {
  String deckId;
  int gameMode;
  bool toFrom;

  GamePage({
    super.key,
    required this.deckId,
    required this.gameMode,
    required this.toFrom,
  }); // 0 - learn, 1 - write, 2 - write level 2

  @override
  State<StatefulWidget> createState() {
    return _game1();
  }
}

class _game1 extends State<GamePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _translationController = TextEditingController();
  final FocusNode _pageFocusNode = FocusNode();

  List<FlashCard> _currentCards = [];
  int _currentIndex = 0;
  bool _showAnswer = false;
  bool _wasAddedInArr = false;
  int _lenght = 0;

  Future<Set<String>> _getSubDecks(String deckId) async {
    final User? user = _auth.currentUser;
    if (user == null) {
      return <String>{};
    }

    final Set<String> allSubDeckIds = <String>{};

    Query query = _firestore
        .collection("decks")
        .where("userId", isEqualTo: user.uid)
        .where("parentId", isEqualTo: deckId);

    try {
      QuerySnapshot querySnap = await query.get();

      final List<String> directSubDeckIdsFound = [];
      if (querySnap.docs.isNotEmpty) {
        for (QueryDocumentSnapshot docSnap in querySnap.docs) {
          directSubDeckIdsFound.add(docSnap.id);
        }
      }

      allSubDeckIds.addAll(directSubDeckIdsFound);

      for (String id in directSubDeckIdsFound) {
        final Set<String> nestedSubDecks = await _getSubDecks(id);
        allSubDeckIds.addAll(nestedSubDecks);
      }
    } catch (e) {
      print("Помилка під час отримання підколод для $deckId: $e");
    }

    print("SubDecks: $allSubDeckIds");

    return allSubDeckIds;
  }

  Future<List<FlashCard>> _getCardsForCurrentDeckStream({
    String order = 'nextReviewAt',
  }) async {
    final User? user = _auth.currentUser;
    final allSubDeckIds = await _getSubDecks(widget.deckId);

    allSubDeckIds.add(widget.deckId);

    Query query = _firestore
        .collection('flashcards')
        .where('userId', isEqualTo: user?.uid)
        .where('deckId', whereIn: allSubDeckIds);

    if (widget.gameMode == 0) {
      query = query
          .where('nextReviewAt', isLessThanOrEqualTo: Timestamp.now())
          .where('proficiencyLevel', isLessThan: 6);
    } else if (widget.gameMode == 2) {
      query = query.where('proficiencyLevel', isEqualTo: 1);
    }

    try {
      QuerySnapshot<FlashCard> QuerySnap =
          await query
              .orderBy(order, descending: false)
              .withConverter<FlashCard>(
                fromFirestore: FlashCard.fromFirestore,
                toFirestore: (FlashCard card, _) => card.toFirestore(),
              )
              .get();

      return QuerySnap.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      return [];
    }
  }

  int _intervalDay(int interval) {
    if (interval == 1) {
      return 1;
    } else if (interval == 2) {
      return 2;
    } else if (interval == 3) {
      return 4;
    } else if (interval == 4) {
      return 7;
    } else if (interval == 5) {
      return 10;
    }
    return 15;
  }

  Future<void> _updateCardReview(FlashCard currentCard, bool success) async {
    if (widget.gameMode == 0 || !success) {
      FlashCard updatedCard = currentCard.copyWith(
        updatedAt: Timestamp.now(),
        lastReviewAt: Timestamp.now(),
        nextReviewAt: Timestamp.fromDate(
          Timestamp.now().toDate().add(
            Duration(days: currentCard.intervalDays),
          ),
        ),
        proficiencyLevel: success ? currentCard.proficiencyLevel + 1 : 1,
        timesCorrect:
            success ? currentCard.timesCorrect + 1 : currentCard.timesCorrect,
        timesIncorrect:
            !success
                ? currentCard.timesIncorrect + 1
                : currentCard.timesIncorrect,
        intervalDays: success ? _intervalDay(currentCard.proficiencyLevel) : 1,
      );

      await _firestore
          .collection('flashcards')
          .doc(updatedCard.cardId)
          .withConverter<FlashCard>(
            fromFirestore: FlashCard.fromFirestore,
            toFirestore: (FlashCard card, _) => card.toFirestore(),
          )
          .set(updatedCard);
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _translationController.dispose();
    _pageFocusNode.dispose();
    super.dispose();
  }

  void _toggleShowAnswer() {
    setState(() {
      _showAnswer = true;
    });
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.enter) {
        _checkOrGoNext();

        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  void _checkOrGoNext({bool isCorrect = false}) {
    print("_checkOrGN");
    if (_currentCards.isEmpty) return;
    print("_checkOrGN2");

    final String currentInput = _translationController.text;
    _translationController.text = "";

    final currentCard = _currentCards[_currentIndex];

    if (!_showAnswer || isCorrect) {
      bool correct =
          currentInput.trim().toLowerCase() ==
          (widget.toFrom
              ? currentCard.wordFrom.trim().toLowerCase()
              : currentCard.wordTo.trim().toLowerCase());
      setState(() {
        if (correct || isCorrect) {
          print("Correct!");
          if (!isCorrect) {
            if (mounted) {
              showSuccessSnackbar(context, "Correct!");
            }
          }
          _updateCardReview(currentCard, true);
          _goToNextCard();
        } else {
          if (_showAnswer) {
            _updateCardReview(currentCard, false);
          } else {
            if (mounted) {
              showErrorSnackbar(
                context,
                "Incorrect! Correct answer: ${widget.toFrom ? currentCard.wordFrom : currentCard.wordTo}",
              );
            }
          }
          _toggleShowAnswer();
        }
      });
    } else {
      setState(() {
        _showAnswer = false;
        if (!_wasAddedInArr) {
          _currentCards.add(currentCard);
          _wasAddedInArr = true;
          _updateCardReview(currentCard, false);
        }
      });
    }
  }

  void _goToNextCard() {
    if (_currentCards.isEmpty) return;
    setState(() {
      if (_currentIndex < _currentCards.length - 1) {
        _currentIndex++;
      } else {
        _currentIndex = 0;
        if (mounted) {
          showSuccessSnackbar(context, "You've viewed all the cards!");
        }
        Navigator.pop(context);
      }
      _showAnswer = false;
      _wasAddedInArr = false;
      _translationController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).requestFocus(_pageFocusNode);
      },
      child: Focus(
        focusNode: _pageFocusNode,
        onKeyEvent: _handleKeyEvent,
        child: Scaffold(
          appBar: AppBar(
            title: Column(
              children: [
                Text("Enter it"),
                _lenght != 0
                    ? Text(
                      "${_currentIndex < _lenght ? _currentIndex : _lenght}/$_lenght",
                      style: TextStyle(
                        fontWeight: FontWeight.w300,
                        fontSize: 15,
                      ),
                    )
                    : Text(""),
              ],
            ),
            centerTitle: true,
            backgroundColor: Theme.of(context).primaryColor,
          ),
          body: FutureBuilder(
            future: _getCardsForCurrentDeckStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                if (widget.gameMode == 0) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                        if (mounted) {
                          showErrorSnackbar(context, "Error occurred");
                        }
                      }
                    }
                  });
                }

                return Center(child: Text('Error loading cards'));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                _currentCards = [];
                _currentIndex = 0;

                if (widget.gameMode == 0) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                        if (mounted) {
                          showErrorSnackbar(context, "No cards to review");
                        }
                      }
                    }
                  });
                }

                return Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('There are no cards in this deck yet'),
                  ),
                );
              }

              if (_currentCards.isEmpty) {
                _currentCards = snapshot.data!;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    setState(() {
                      _lenght = _currentCards.length;
                    });
                  }
                });
              }

              if (_currentCards.isEmpty) {
                return Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'There are still no cards in this deck (updated).',
                    ),
                  ),
                );
              }

              if (_currentIndex >= _currentCards.length) {
                _currentIndex = _currentCards.length - 1;
              }

              final currentCard = _currentCards[_currentIndex];
              final String textToShow =
                  _showAnswer
                      ? (widget.toFrom
                          ? currentCard.wordFrom
                          : currentCard.wordTo)
                      : (widget.toFrom
                          ? currentCard.wordTo
                          : currentCard.wordFrom);

              final String exampleToShow =
                  _showAnswer
                      ? (widget.toFrom
                          ? currentCard.exampleSentenceFrom ?? ""
                          : currentCard.exampleSentenceTo ?? "")
                      : (widget.toFrom
                          ? currentCard.exampleSentenceTo ?? ""
                          : currentCard.exampleSentenceFrom ?? "");

              return Column(
                children: [
                  Expanded(
                    flex: 3,
                    child: Padding(
                      padding: EdgeInsets.all(6),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  textToShow,
                                  style: TextStyle(
                                    fontSize: 35,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (exampleToShow.isNotEmpty)
                                  Text(
                                    exampleToShow,
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w300,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Padding(
                      padding: EdgeInsets.all(6),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20),
                            child: TextField(
                              controller: _translationController,
                              decoration: InputDecoration(
                                hintText: "Enter here",
                              ),
                              enabled: !_showAnswer,
                              autofocus: true,
                              onSubmitted: (_) => _checkOrGoNext(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: EdgeInsets.all(6),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 6,
                                    ),
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        disabledForegroundColor:
                                            Theme.of(
                                              context,
                                            ).colorScheme.secondary,
                                      ),
                                      onPressed:
                                          _showAnswer
                                              ? () => _checkOrGoNext(
                                                isCorrect: true,
                                              )
                                              : _toggleShowAnswer,
                                      child: Text(
                                        _showAnswer ? "Correct" : "Show",
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 6,
                                    ),
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        disabledForegroundColor:
                                            Theme.of(
                                              context,
                                            ).colorScheme.secondary,
                                      ),
                                      onPressed: _checkOrGoNext,
                                      child: Text(
                                        _showAnswer ? "Repeat" : "Next",
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
