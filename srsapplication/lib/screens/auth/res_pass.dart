import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ResPass extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _resetPasswordPage();
  }
}

class _resetPasswordPage extends State<ResPass> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  void _showErrorSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  Future<void> _resetPasswordRequest(String email) async {
    if (email.trim().isEmpty) {
      _showErrorSnackbar("Поле email не може бути порожнім");
      return;
    } else if (!email.trim().contains("@") || !email.trim().contains(".")) {
      _showErrorSnackbar("Будь ласка, введіть коректну email адресу.");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _auth.sendPasswordResetEmail(email: email);
      _showSuccessSnackbar(
        "Email для відновлення пароля було надіслано на електронну адресу",
      );
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    } on FirebaseAuthException catch (e) {
      String message = "Не вдалося надіслати лист для скидання пароля.";
      if (e.code == 'user-not-found') {
        message = "Користувача з таким email не знайдено.";
      } else if (e.code == 'invalid-email') {
        message = "Вказано некоректну email адресу.";
      }
      // Можна додати інші коди помилок з документації Firebase
      _showErrorSnackbar(message);
      print(
        "FirebaseAuthException on password reset: ${e.code} - ${e.message}",
      );
    } catch (e) {
      _showErrorSnackbar("Сталась невідома помилка. Спробуйте пізніше.");
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
      appBar: AppBar(centerTitle: true, title: Text("Cкинути пароль")),
      body: Center(
        child: Form(
          key: _formKey,
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 125),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/icon_dp.png',
                  fit: BoxFit.cover,
                  width: 120,
                ),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: "Email",
                    helperText: "Введіть Email для скидання пароля",
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                SizedBox(height: 15),
                if (_isLoading)
                  CircularProgressIndicator()
                else
                  ElevatedButton(
                    onPressed: () {
                      _resetPasswordRequest(_emailController.text.trim());
                    },
                    child: Text("Cкинути пароль"),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
