import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:srsapplication/screens/auth/auth_gate.dart';
import 'package:srsapplication/screens/auth/auth_screen.dart';
import 'package:srsapplication/screens/auth/res_pass.dart';
import 'firebase_options.dart';
import 'package:srsapplication/themes/themes.dart';
import 'package:srsapplication/screens/deck/deck_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SRS Flashcards',
      theme: white_theme(context),
      darkTheme: dark_theme(context),
      themeMode: ThemeMode.system,
      home: const AuthGate(),
      routes: {
        '/auth': (context) => const AuthScreen(),
        '/home': (context) => const DeckScreen(),
        '/resetPassword': (context) => ResPass(),
      },
    );
  }
}
