import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:srsapplication/models/card_model.dart';

import '../../func/card_deck/func.dart';
import '../../func/messages/snackbars.dart';

class CreateEditCardScreen extends StatefulWidget {
  final String deckId;
  final FlashCard? existingCard;

  const CreateEditCardScreen({
    super.key,
    required this.deckId,
    this.existingCard,
  });

  @override
  State<CreateEditCardScreen> createState() => _CreateEditCardScreenState();
}

class _CreateEditCardScreenState extends State<CreateEditCardScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _wordFromController;
  late TextEditingController _wordToController;
  late TextEditingController _exampleFromController;
  late TextEditingController _exampleToController;
  late TextEditingController _transcriptionController;

  bool _isLoading = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool get _isEditing => widget.existingCard != null;

  @override
  void initState() {
    super.initState();
    _wordFromController = TextEditingController(
      text: widget.existingCard?.wordFrom ?? '',
    );
    _wordToController = TextEditingController(
      text: widget.existingCard?.wordTo ?? '',
    );
    _exampleFromController = TextEditingController(
      text: widget.existingCard?.exampleSentenceFrom ?? '',
    );
    _exampleToController = TextEditingController(
      text: widget.existingCard?.exampleSentenceTo ?? '',
    );
    _transcriptionController = TextEditingController(
      text: widget.existingCard?.transcription ?? '',
    );
  }

  @override
  void dispose() {
    _wordFromController.dispose();
    _wordToController.dispose();
    _exampleFromController.dispose();
    _exampleToController.dispose();
    _transcriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveCard() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_auth.currentUser == null) {
      if (mounted) {
        showErrorSnackbar(context, 'Помилка: користувач не автентифікований.');
      }

      return;
    }

    setState(() {
      _isLoading = true;
    });

    final String wordFrom = _wordFromController.text.trim();
    final String wordTo = _wordToController.text.trim();
    final String? exampleFrom =
        _exampleFromController.text.trim().isNotEmpty
            ? _exampleFromController.text.trim()
            : null;
    final String? exampleTo =
        _exampleToController.text.trim().isNotEmpty
            ? _exampleToController.text.trim()
            : null;
    final String? transcription =
        _transcriptionController.text.trim().isNotEmpty
            ? _transcriptionController.text.trim()
            : null;

    final User currentUser = _auth.currentUser!;
    final Timestamp now = Timestamp.now();

    try {
      if (_isEditing) {
        FlashCard updatedCard = widget.existingCard!.copyWith(
          wordFrom: wordFrom,
          wordTo: wordTo,
          exampleSentenceFrom: exampleFrom,
          exampleSentenceTo: exampleTo,
          transcription: transcription,
          updatedAt: now,
        );

        await _firestore
            .collection('flashcards')
            .doc(updatedCard.cardId)
            .withConverter<FlashCard>(
              fromFirestore: FlashCard.fromFirestore,
              toFirestore: (FlashCard card, _) => card.toFirestore(),
            )
            .set(updatedCard);

        if (mounted) {
          if (mounted) {
            showSuccessSnackbar(context, "Картку оновленно");
          }
          Navigator.of(context).pop();
        }
      } else {
        DocumentReference cardRef = _firestore.collection('flashcards').doc();

        FlashCard newCard = FlashCard(
          cardId: cardRef.id,
          wordFrom: wordFrom,
          wordTo: wordTo,
          exampleSentenceFrom: exampleFrom,
          exampleSentenceTo: exampleTo,
          transcription: transcription,
          createdAt: now,
          updatedAt: now,
          deckId: widget.deckId,
          userId: currentUser.uid,
          proficiencyLevel: 0,
          intervalDays: 1,
          lastReviewAt: null,
          nextReviewAt: now,
          timesCorrect: 0,
          timesIncorrect: 0,
        );

        await cardRef.set(newCard.toFirestore());

        try {
          final deckDocRef = _firestore.collection('decks').doc(widget.deckId);
          await deckDocRef.update({'cardCount': FieldValue.increment(1)});
        } catch (e) {
          print("Помилка оновлення лічильника карток у колоді: $e");
        }

        if (mounted) {
          if (mounted) {
            showSuccessSnackbar(context, 'Картку створено!');
          }
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackbar(context, "Помилка створення картки");
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Редагувати картку' : 'Створити нову картку'),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveCard,
              tooltip: 'Зберегти картку',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextFormField(
                controller: _wordFromController,
                decoration: InputDecoration(
                  labelText: 'Слово / Фраза (мова оригіналу)',
                  hintText: 'Наприклад, "Hello"',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Це поле не може бути порожнім.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Поле "Переклад"
              TextFormField(
                controller: _wordToController,
                decoration: InputDecoration(
                  labelText: 'Переклад',
                  hintText: 'Наприклад, "Привіт"',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Це поле не може бути порожнім.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 10),
              Text(
                'Додаткова інформація (опціонально)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),

              // Поле "Приклад речення (мова оригіналу)"
              TextFormField(
                controller: _exampleFromController,
                decoration: InputDecoration(
                  labelText: 'Приклад речення (мова оригіналу)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  alignLabelWithHint: true,
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              // Поле "Переклад прикладу речення"
              TextFormField(
                controller: _exampleToController,
                decoration: InputDecoration(
                  labelText: 'Переклад прикладу речення',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  alignLabelWithHint: true,
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              // Поле "Транскрипція"
              TextFormField(
                controller: _transcriptionController,
                decoration: InputDecoration(
                  labelText: 'Транскрипція',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              ElevatedButton.icon(
                icon:
                    _isLoading
                        ? Container(
                          width: 24,
                          height: 24,
                          padding: const EdgeInsets.all(2.0),
                          child: const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                        : const Icon(Icons.save),
                label: Text(_isEditing ? 'Оновити картку' : 'Створити картку'),
                onPressed: _isLoading ? null : _saveCard,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  textStyle: const TextStyle(fontSize: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
