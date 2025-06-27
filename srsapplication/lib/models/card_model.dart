import 'package:cloud_firestore/cloud_firestore.dart';

class FlashCard {
  final String cardId;
  final String userId;
  final String wordFrom;
  final String wordTo;
  final String? exampleSentenceFrom;
  final String? exampleSentenceTo;
  final String? transcription;
  final Timestamp createdAt;
  final Timestamp updatedAt;
  final Timestamp? lastReviewAt;
  final Timestamp? nextReviewAt;
  final int proficiencyLevel;
  final int intervalDays;
  final int timesCorrect;
  final int timesIncorrect;
  final String deckId;

  FlashCard({
    required this.cardId,
    required this.userId,
    required this.wordFrom,
    required this.wordTo,
    this.exampleSentenceFrom,
    this.exampleSentenceTo,
    this.transcription,
    required this.createdAt,
    required this.updatedAt,
    this.lastReviewAt,
    this.nextReviewAt,
    this.proficiencyLevel = 0,
    this.intervalDays = 1,
    this.timesCorrect = 0,
    this.timesIncorrect = 0,
    required this.deckId,
  });

  factory FlashCard.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    if (data == null) {
      throw FirebaseException(
        plugin: 'Firestore',
        message: 'Дані для FlashCard відсутні',
      );
    }
    return FlashCard(
      cardId: snapshot.id,
      userId: data['userId'] ?? '',
      wordFrom: data['wordFrom'] ?? '',
      wordTo: data['wordTo'] ?? '',
      exampleSentenceFrom: data['exampleSentenceFrom'],
      exampleSentenceTo: data['exampleSentenceTo'],
      transcription: data['transcription'],
      createdAt: data['createdAt'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'] ?? Timestamp.now(),
      lastReviewAt: data['lastReviewAt'],
      nextReviewAt: data['nextReviewAt'],
      proficiencyLevel: data['proficiencyLevel'] ?? 0,
      intervalDays: data['intervalDays'] ?? 1,
      timesCorrect: data['timesCorrect'] ?? 0,
      timesIncorrect: data['timesIncorrect'] ?? 0,
      deckId: data['deckId'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'wordFrom': wordFrom,
      'wordTo': wordTo,
      if (exampleSentenceFrom != null)
        'exampleSentenceFrom': exampleSentenceFrom,
      if (exampleSentenceTo != null) 'exampleSentenceTo': exampleSentenceTo,
      if (transcription != null) 'transcription': transcription,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      if (lastReviewAt != null) 'lastReviewAt': lastReviewAt,
      if (nextReviewAt != null) 'nextReviewAt': nextReviewAt,
      'proficiencyLevel': proficiencyLevel,
      'intervalDays': intervalDays,
      'timesCorrect': timesCorrect,
      'timesIncorrect': timesIncorrect,
      'deckId': deckId,
    };
  }

  FlashCard copyWith({
    String? userId,
    String? cardId,
    String? wordFrom,
    String? wordTo,
    String? exampleSentenceFrom,
    String? exampleSentenceTo,
    String? transcription,
    Timestamp? createdAt,
    Timestamp? updatedAt,
    Timestamp? lastReviewAt,
    Timestamp? nextReviewAt,
    int? proficiencyLevel,
    int? intervalDays,
    int? timesCorrect,
    int? timesIncorrect,
    String? deckId,
  }) {
    return FlashCard(
      userId: userId ?? this.userId,
      cardId: cardId ?? this.cardId,
      wordFrom: wordFrom ?? this.wordFrom,
      wordTo: wordTo ?? this.wordTo,
      exampleSentenceFrom: exampleSentenceFrom ?? this.exampleSentenceFrom,
      exampleSentenceTo: exampleSentenceTo ?? this.exampleSentenceTo,
      transcription: transcription ?? this.transcription,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastReviewAt: lastReviewAt ?? this.lastReviewAt,
      nextReviewAt: nextReviewAt ?? this.nextReviewAt,
      proficiencyLevel: proficiencyLevel ?? this.proficiencyLevel,
      intervalDays: intervalDays ?? this.intervalDays,
      timesCorrect: timesCorrect ?? this.timesCorrect,
      timesIncorrect: timesIncorrect ?? this.timesIncorrect,
      deckId: deckId ?? this.deckId,
    );
  }
}
