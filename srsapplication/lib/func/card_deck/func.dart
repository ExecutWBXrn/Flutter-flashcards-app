import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:srsapplication/models/deck_model.dart';

Stream<List<Deck>> getUserDecksStream(
  String? parentId, {
  String order = 'createdAt',
}) {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? user = _auth.currentUser;

  if (user == null) {
    return Stream.value([]);
  }

  Query query = _firestore
      .collection('decks')
      .where('userId', isEqualTo: user.uid);

  if (parentId == null) {
    query = query.where('parentId', isNull: true);
  } else {
    query = query.where('parentId', isEqualTo: parentId);
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

Future<bool> getRepeatDecks(String deck) async {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth user = FirebaseAuth.instance;

  User? _currentUser = user.currentUser;
  bool res = false;

  Query query = _firestore
      .collection("flashcards")
      .where('userId', isEqualTo: _currentUser?.uid)
      .where("deckId", isEqualTo: deck)
      .where('nextReviewAt', isLessThanOrEqualTo: Timestamp.now())
      .where('proficiencyLevel', isGreaterThanOrEqualTo: 1)
      .limit(1);

  try {
    QuerySnapshot qSs = await query.get();

    if (qSs.docs.isNotEmpty) {
      res = true;
    }
  } catch (e) {
    print("Помилка у спробі отримання картки для повторення у колоді");
  }

  return res;
}
