import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:srsapplication/models/card_model.dart';
import 'package:srsapplication/models/deck_model.dart';

class Info extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Info({super.key});

  Stream<List<Deck>> _getUserDecksStream() {
    final User? user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('decks')
        .where('userId', isEqualTo: user.uid)
        .withConverter<Deck>(
          fromFirestore: Deck.fromFirestore,
          toFirestore: (Deck deck, _) => deck.toFirestore(),
        )
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Stream<List<FlashCard>> _getUserCardsStream() {
    final User? user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('flashcards')
        .where('userId', isEqualTo: user.uid)
        .withConverter<FlashCard>(
          fromFirestore: FlashCard.fromFirestore,
          toFirestore: (FlashCard card, _) => card.toFirestore(),
        )
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  int _cardCount(List<Deck> decks) {
    int _cardCount = 0;
    for (Deck deck in decks) {
      _cardCount += deck.cardCount;
    }
    return _cardCount;
  }

  Map<String, dynamic> _cardLearning(List<FlashCard> cards) {
    Map<String, dynamic> res = {};
    bool _isFirstIteration = true;
    int _cardCount = 0;
    int _cardStudied = 0;
    int incorrect = 0;
    int correct = 0;
    String incorrectText = '';
    String correctText = '';
    for (FlashCard card in cards) {
      if (!_isFirstIteration) {
        if (incorrect <= card.timesIncorrect) {
          incorrect = card.timesIncorrect;
          incorrectText = "${card.wordFrom}/${card.wordTo}";
        }
        if (correct <= card.timesCorrect) {
          correct = card.timesCorrect;
          correctText = "${card.wordFrom}/${card.wordTo}";
        }
      } else {
        incorrect = card.timesIncorrect;
        correct = card.timesCorrect;
        _isFirstIteration = false;
      }

      if (card.proficiencyLevel < 6) {
        _cardCount++;
      } else if (card.proficiencyLevel >= 6) {
        _cardStudied++;
      }
    }

    res = {
      'cardCount': _cardCount,
      'cardStudied': _cardStudied,
      'incorrect': incorrect,
      'correct': correct,
      'incorrectText': incorrectText,
      'correctText': correctText,
    };

    return res;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(centerTitle: true, title: Text("Statistics")),
      body: CustomScrollView(
        slivers: [
          StreamBuilder(
            stream: _getUserDecksStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError) {
                return const SliverToBoxAdapter(
                  child: Center(child: Text('Error loading decks!')),
                );
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('There are no cards in this deck yet'),
                    ),
                  ),
                );
              }

              final data = snapshot.data;

              return SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Decks",
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.start,
                      ),
                      SizedBox(height: 15),
                      Text("Number of decks: ${data?.length}."),
                      SizedBox(height: 15),
                      Text(
                        "Cards",
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 15),
                      Text("Total number of cards: ${_cardCount(data!)}."),
                    ],
                  ),
                ),
              );
            },
          ),
          StreamBuilder(
            stream: _getUserCardsStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError) {
                print("Snap err: ${snapshot.error}");
                return const SliverToBoxAdapter(
                  child: Center(child: Text('Error loading cards!')),
                );
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('There are no cards in this deck yet.'),
                    ),
                  ),
                );
              }

              final data = snapshot.data;

              final cardData = _cardLearning(data!);

              return SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Cards in progress: ${cardData['cardCount']}."),
                      Text("Cards learned: ${cardData['cardStudied']}."),
                      Text("Most correct answers (${cardData['correct']}):"),
                      Text(cardData['correctText']),
                      Text("Least correct answers (${cardData['incorrect']}):"),
                      Text(cardData['incorrectText']),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
