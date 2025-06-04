import 'package:flutter/material.dart';
import 'package:srsapplication/models/deck_model.dart';
import 'package:srsapplication/screens/deck/deck_create.dart';

class CardListScreen extends StatefulWidget {
  const CardListScreen({super.key});

  @override
  State<StatefulWidget> createState() {
    return _cardListScreenState();
  }
}

class _cardListScreenState extends State<CardListScreen> {
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
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateEditDeckScreen()),
    );
    print("Перехід на екран створення колоди");
  }

  void _navigateToDeckDetailScreen(Deck deck) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CardListScreen()),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Картки'),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
        actions: [IconButton(onPressed: () {}, icon: Icon(Icons.more_vert))],
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
            _buildBottomNavItem(Icons.add, 'Додати картку', () {}),
          ],
        ),
      ),
    );
  }
}
