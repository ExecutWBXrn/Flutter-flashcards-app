import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:srsapplication/screens/auth/auth_gate.dart';
import 'package:srsapplication/screens/auth/auth_screen.dart';
import 'package:srsapplication/screens/auth/res_pass.dart';
import 'firebase_options.dart';
import 'package:srsapplication/themes/themes.dart';
import 'package:srsapplication/screens/deck/deck_screen.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    ChangeNotifierProvider(create: (_) => ThemeProvider(), child: MyApp()),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      title: 'SRS Flashcards',
      theme: white_theme(context),
      darkTheme: dark_theme(context),
      themeMode: themeProvider.themeMode,
      home: const AuthGate(),
      debugShowCheckedModeBanner: false,
      routes: {
        '/auth': (context) => const AuthScreen(),
        '/home': (context) => const DeckScreen(),
        '/resetPassword': (context) => ResPass(),
      },
    );
  }
}

// Copyright (c) 2025 Roman Beniuk. All Rights Reserved.
