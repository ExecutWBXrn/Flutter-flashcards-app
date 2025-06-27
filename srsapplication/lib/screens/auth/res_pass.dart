import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../func/card_deck/func.dart';
import '../../func/messages/snackbars.dart';

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

  Future<void> _resetPasswordRequest(String email) async {
    if (email.trim().isEmpty) {
      if (mounted) {
        showErrorSnackbar(context, "Email field cannot be empty");
      }

      return;
    } else if (!email.trim().contains("@") || !email.trim().contains(".")) {
      if (mounted) {
        showErrorSnackbar(context, "Please enter a valid email address");
      }

      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _auth.sendPasswordResetEmail(email: email);
      if (mounted) {
        showSuccessSnackbar(
          context,
          "A password reset email has been sent to your email address",
        );
      }

      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    } on FirebaseAuthException catch (e) {
      String message = "Failed to send password reset email";
      if (e.code == 'user-not-found') {
        message = "No user found with this email";
      } else if (e.code == 'invalid-email') {
        message = "Invalid email address provided";
      }
      if (mounted) {
        showErrorSnackbar(context, message);
      }

      print(
        "FirebaseAuthException on password reset: ${e.code} - ${e.message}",
      );
    } catch (e) {
      if (mounted) {
        showErrorSnackbar(
          context,
          "An unknown error occurred. Please try again later.",
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(centerTitle: true, title: Text("Reset Password")),
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
                    helperText: "Enter your email to reset your password",
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
                    child: Text("Reset password"),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
