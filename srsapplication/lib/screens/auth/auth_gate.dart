import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:srsapplication/screens/auth/auth_screen.dart';
import 'package:srsapplication/screens/deck/deck_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SplashScreen();
        }

        if (!snapshot.hasData || snapshot.hasData == null) {
          print("user has no data, going to authscreen");
          return const AuthScreen();
        }
        User user = snapshot.data!;

        if (!user.emailVerified) {
          return FutureBuilder(
            key: ValueKey(user.uid),
            future: _getRefreshedUser(user),
            builder: (
              BuildContext context,
              AsyncSnapshot<User?> userRefreshSnapshot,
            ) {
              if (userRefreshSnapshot.hasError) {
                print(
                  "Помилка FutureBuilder при оновленні користувача ${userRefreshSnapshot.error}",
                );
                return AuthScreen();
              }

              User? refreshedUser = userRefreshSnapshot.data;

              if (refreshedUser != null && refreshedUser.emailVerified) {
                return DeckScreen(); // Перенаправляємо на головний екран
              } else {
                return AuthScreen();
              }
            },
          );
        } else {
          print("user logined");
          return DeckScreen();
        }
      },
    );
  }

  Future<User?> _getRefreshedUser(User? user) async {
    if (user == null) return null;
    try {
      await user.reload();
      return FirebaseAuth.instance.currentUser;
    } catch (e) {
      print("Помилка при user.reload(): $e");
      return FirebaseAuth.instance.currentUser;
    }
  }
}

class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}
