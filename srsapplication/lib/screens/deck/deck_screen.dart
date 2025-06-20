import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:srsapplication/models/deck_model.dart';
import 'package:srsapplication/screens/deck/deck_create.dart';
import 'package:srsapplication/screens/card/cards_screen.dart';
import 'package:srsapplication/screens/drawer/about.dart';
import 'package:srsapplication/screens/drawer/settings.dart';
import 'package:srsapplication/screens/drawer/info.dart';
import 'package:srsapplication/themes/themes.dart';
import 'package:srsapplication/screens/games/game.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeckScreen extends StatefulWidget {
  final String? parentId;
  final String? parentDeckName;
  final bool? toFrom;

  const DeckScreen({
    super.key,
    this.parentId,
    this.parentDeckName,
    this.toFrom,
  });

  @override
  State<StatefulWidget> createState() {
    return _DeckScreenState();
  }
}

enum MenuAction { edit, delete }

enum GameAction { learn, repeat, repeat2 }

class _DeckScreenState extends State<DeckScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _currentUser;
  Deck? _choosenDeck;
  bool? _currentFrom;

  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser;
    _currentFrom = widget.toFrom ?? true;
    _initializeAsyncData();
    print(
      "[DeckScreen CONSTRUCTOR] parentId: ${widget.parentId}, parentDeckName: ${widget.parentDeckName}",
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

  Stream<List<Deck>> _getUserDecksStream() {
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
        .orderBy('createdAt', descending: true)
        .withConverter<Deck>(
          fromFirestore: Deck.fromFirestore,
          toFirestore: (Deck deck, _) => deck.toFirestore(),
        )
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  void _navigateToCreateDeckScreen() {
    setState(() {
      _choosenDeck = null;
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

  void _showErrorSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  Future<void> deleteDeck(String deckId) async {
    final deckService = DeckService();
    await deckService.deleteDeckHierarchically(deckId);
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

  @override
  Widget build(BuildContext context) {
    final User? currentUser = _auth.currentUser;
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Колоди'),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          if (_choosenDeck != null)
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
                  deleteDeck(_choosenDeck!.id);
                } else if (action == MenuAction.edit) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) =>
                              CreateEditDeckScreen(deckToEdit: _choosenDeck),
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
                  Text(_currentFrom! ? "M" : "S"),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _currentFrom = !_currentFrom!;
                      });
                      _saveData(_currentFrom!);
                    },
                    icon: Icon(Icons.compare_arrows),
                  ),
                  Text(_currentFrom! ? "S" : "M"),
                ],
              ),
            ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(
                    themeProvider.isCurrentlyDark(context)
                        ? "assets/images/backgrounds/dark_header.png"
                        : "assets/images/backgrounds/white_header.png",
                  ),
                  fit: BoxFit.contain,
                  repeat: ImageRepeat.repeat,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    backgroundImage:
                        (_auth.currentUser?.photoURL != null)
                            ? NetworkImage(_auth.currentUser!.photoURL!)
                            : null,
                    child:
                        (_auth.currentUser?.photoURL! == null)
                            ? Text(
                              _auth.currentUser?.email?[0].toUpperCase() ?? 'U',
                              style: TextStyle(
                                fontSize: 24,
                                color: Theme.of(context).primaryColor,
                              ),
                            )
                            : null,
                  ),
                  SizedBox(height: 8),
                  Text(
                    _auth.currentUser?.displayName ??
                        _auth.currentUser?.email ??
                        'Користувач',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 16,
                    ),
                  ),
                  if (_auth.currentUser?.displayName == null &&
                      _auth.currentUser?.email != null)
                    Text(
                      _auth.currentUser!.email!,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Головна'),
              splashColor: Theme.of(
                context,
              ).colorScheme.primary.withOpacity(0.1),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Налаштування'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SettingsPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.line_axis),
              title: const Text('Статистика'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Info()),
                );
              },
            ),
            const Divider(), // Розділювач
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Про додаток'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AboutPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Вийти'),
              onTap: () async {
                Navigator.pop(context);
                await _auth.signOut();
              },
            ),
          ],
        ),
      ),
      body: StreamBuilder<List<Deck>>(
        stream: _getUserDecksStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            print("Помилка завантаження колод: ${snapshot.error}");
            return const Center(child: Text('Не вдалося завантажити колоди.'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('У вас ще немає жодної колоди.'),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _navigateToCreateDeckScreen,
                    child: const Text('Створити першу колоду'),
                  ),
                ],
              ),
            );
          }

          final decks = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: decks.length,
            itemBuilder: (context, index) {
              final deck = decks[index];

              return Card(
                margin: EdgeInsets.symmetric(vertical: 8),
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
                  trailing: PopupMenuButton<GameAction>(
                    icon: Icon(Icons.play_arrow, size: 40, color: Colors.green),
                    itemBuilder:
                        (BuildContext context) => <PopupMenuEntry<GameAction>>[
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
                              leading: Icon(Icons.assignment_outlined),
                              title: Text('Write it'),
                            ),
                          ),
                          const PopupMenuItem<GameAction>(
                            value: GameAction.repeat2,
                            child: ListTile(
                              leading: Icon(Icons.assignment_outlined),
                              title: Text('Write it mode 2'),
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
                        _showErrorSnackbar(
                          "Додайте картки в колоду для їхнього вивчення",
                        );
                      }
                    },
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
            },
          );
        },
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
            _buildBottomNavItem(Icons.add, 'Додати картку', () {
              _showErrorSnackbar("Виберіть колоду для додавання картки");
            }),
          ],
        ),
      ),
    );
  }
}
