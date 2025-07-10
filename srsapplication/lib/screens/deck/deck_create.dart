import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:srsapplication/models/deck_model.dart';

import '../../func/messages/snackbars.dart';

class CreateEditDeckScreen extends StatefulWidget {
  final Deck? deckToEdit;
  final String? parentDeckId;

  const CreateEditDeckScreen({super.key, this.deckToEdit, this.parentDeckId});

  @override
  State<CreateEditDeckScreen> createState() => _CreateEditDeckScreenState();
}

class _CreateEditDeckScreenState extends State<CreateEditDeckScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;

  String? _selectedLanguageFrom;
  String? _selectedLanguageTo;

  bool _isLoading = false;
  bool get _isEditing => widget.deckToEdit != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.deckToEdit?.name ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.deckToEdit?.description ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveDeck() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        if (mounted) {
          showErrorSnackbar(context, 'Error: user is not authenticated');
        }
        setState(() {
          _isLoading = false;
        });
        return;
      }

      try {
        final now = Timestamp.now();
        final deckData = {
          'userId': currentUser.uid,
          'name': _nameController.text.trim(),
          'description':
              _descriptionController.text.trim().isNotEmpty
                  ? _descriptionController.text.trim()
                  : null,
          'languageFrom': _selectedLanguageFrom,
          'languageTo': _selectedLanguageTo,
          'updatedAt': now,
          'parentId': widget.deckToEdit?.parentId ?? widget.parentDeckId,
        };

        if (_isEditing && widget.deckToEdit != null) {
          await _firestore
              .collection('decks')
              .doc(widget.deckToEdit!.id)
              .update(deckData);
          if (mounted) {
            showSuccessSnackbar(context, 'Deck updated successfully!');
          }
        } else {
          deckData['createdAt'] = now;
          deckData['cardCount'] = 0;
          await _firestore.collection('decks').add(deckData);
          if (mounted) {
            showSuccessSnackbar(context, 'Deck created successfully!');
          }
        }
        Navigator.pop(context);
      } catch (e) {
        print("Помилка збереження колоди: $e");
        if (mounted) {
          showErrorSnackbar(
            context,
            'Failed to save the deck. An unknown error occurred',
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit deck' : 'Create new deck'),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveDeck,
              tooltip: 'Save',
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
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Deck name *',
                  hintText: 'e.g., "English B2 adverbs"',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Name cannot be empty';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  hintText: "A short description of the deck's content",
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 32.0),
              ElevatedButton.icon(
                icon: const Icon(Icons.save_alt_rounded),
                label: Text(_isLoading ? 'Saving...' : 'Save deck'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: _isLoading ? null : _saveDeck,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
