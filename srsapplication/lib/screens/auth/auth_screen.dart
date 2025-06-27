import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../func/card_deck/func.dart';
import '../../func/messages/snackbars.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<StatefulWidget> createState() {
    return _AuthScreenState();
  }
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  bool _isLoginMode = true;
  String _email = '';
  String _password = '';
  bool _isLoading = false;
  bool _isResendButtonDisabled = false;
  int _countdownSeconds = 0;
  Timer? _timer;
  bool _isTriedToReg = false;
  bool _obsPassword = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _signInWithGoogle() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );
    } on FirebaseAuthException catch (e) {
      String message = "Помилка входу через Google. Спробуйте пізніше.";
      if (e.code == 'account-exists-with-different-credential') {
        message =
            "Акаунт вже існує з іншим методом входу. Спробуйте увійти цим методом.";
      } else if (e.code == 'invalid-credential') {
        message = "Недійсні облікові дані Google.";
      }
      if (mounted) {
        showErrorSnackbar(context, message);
      }
      print(
        "FirebaseAuthException під час входу через Google: ${e.code} - ${e.message}",
      );
    } catch (e) {
      if (mounted) {
        showErrorSnackbar(
          context,
          "Сталася помилка під час входу через Google",
        );
      }
      print("Помилка під час входу через Google: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _startResendCooldownTimer(int per) {
    setState(() {
      _isResendButtonDisabled = true;
      _countdownSeconds = per;
    });

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_countdownSeconds > 0) {
          _countdownSeconds--;
        } else {
          _timer?.cancel();
          _isResendButtonDisabled = false;
        }
      });
    });
  }

  Future<void> _sendVerificationEmailAgain() async {
    if (_isResendButtonDisabled) return;

    User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      if (mounted) {
        showErrorSnackbar(
          context,
          "Неможливо відправити лист: користувач не увійшов.",
        );
      }

      return;
    }
    if (currentUser.emailVerified) {
      if (mounted) {
        showErrorSnackbar(context, "Ваш email вже підтверджено.");
      }

      setState(() {
        _isResendButtonDisabled = true;
      });
      return;
    }

    try {
      await currentUser.sendEmailVerification();
      print("Verification email resent to ${currentUser.email}");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Лист для підтвердження повторно відправлено на ${currentUser.email}",
          ),
          backgroundColor: Colors.green,
        ),
      );
      _startResendCooldownTimer(30);
    } catch (e) {
      print("Error resending verification email: $e");
      if (mounted) {
        showErrorSnackbar(
          context,
          "Не вдалось повторно відправити лист. Спробуйте пізніше.",
        );
      }
    }
  }

  Future<void> _sendInitialVerificationEmail(
    UserCredential userCredential,
  ) async {
    try {
      await userCredential.user!.sendEmailVerification();
      print("Verification email sent to ${userCredential.user!.email}");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Лист для підтвердження відправлено на ${userCredential.user!.email}",
          ),
          backgroundColor: Colors.green,
        ),
      );
      if (mounted) {
        setState(() {
          _isTriedToReg = true;
          _isLoginMode = true;
        });
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackbar(
          context,
          "Не вдалось відправити лист для підтвердження. Спробуйте пізніше.",
        );
      }
    }
  }

  void _submitAuthForm() async {
    final isValid = _formKey.currentState?.validate();
    if (isValid == null || !isValid) {
      return;
    }
    _formKey.currentState?.save();

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isLoginMode) {
        UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: _email.trim(),
          password: _password.trim(),
        );
        print("Logged in: ${userCredential.user?.uid}");
        if (userCredential.user != null &&
            !userCredential.user!.emailVerified) {
          if (mounted) {
            showErrorSnackbar(
              context,
              "Ваш email ще не підтверджено. Будь ласка, перевірте свою пошту.",
            );
          }
          setState(() {
            _isTriedToReg = true;
            _isResendButtonDisabled = false;
          });
        }
      } else {
        UserCredential userCredential = await _auth
            .createUserWithEmailAndPassword(
              email: _email.trim(),
              password: _password.trim(),
            );
        print("Registered: ${userCredential.user?.uid}");
        if (userCredential.user != null) {
          _sendInitialVerificationEmail(userCredential);
          setState(() {
            _isTriedToReg = true;
          });
        }
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Сталась помилка';
      if (e.message != null) {
        message = e.message!;
      } else if (e.code == 'user-not-found') {
        message = 'користувача з таким email не знайдено';
      } else if (e.code == 'wrong-password') {
        message = 'Неправильний пароль.';
      } else if (e.code == 'email-already-in-use') {
        message = 'Цей email вже використовується іншим акаунтом.';
      }
      if (mounted) {
        showErrorSnackbar(context, message);
      }
    } catch (e) {
      print(e);
      if (mounted) {
        showErrorSnackbar(context, "Невідома помилка. Спробуйте ще раз.");
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
        title: Text(_isLoginMode ? 'Вхід' : 'Реєстрація'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Image.asset(
                  'assets/images/icon_dp.png',
                  fit: BoxFit.cover,
                  width: 120,
                ),
                TextFormField(
                  key: ValueKey('email'),
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(labelText: 'Email'),
                  validator: (value) => _email_validator(value),
                  onSaved: (v) {
                    _email = v ?? '';
                  },
                ),
                SizedBox(height: 15),
                TextFormField(
                  key: ValueKey('password'),
                  keyboardType: TextInputType.visiblePassword,
                  decoration: InputDecoration(
                    labelText: 'Пароль',
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          _obsPassword = !_obsPassword;
                        });
                      },
                      icon: Icon(
                        _obsPassword ? Icons.visibility_off : Icons.visibility,
                      ),
                    ),
                  ),
                  validator: (value) => _password_validator(value),
                  onSaved: (v) {
                    _password = v ?? '';
                  },
                  obscureText: _obsPassword,
                ),
                if (_isTriedToReg)
                  Container(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed:
                          _isResendButtonDisabled
                              ? null
                              : _sendVerificationEmailAgain,
                      child: Text(
                        _isResendButtonDisabled
                            ? 'Повторно відправити лист через: $_countdownSeconds'
                            : 'Відправити лист повторно',
                      ),
                    ),
                  )
                else if (_isLoginMode)
                  Container(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/resetPassword');
                      },
                      child: Text("Забули пароль ?"),
                    ),
                  ),
                SizedBox(height: 20),
                if (_isLoading)
                  const CircularProgressIndicator()
                else
                  ElevatedButton(
                    onPressed: _submitAuthForm,
                    child: Text(_isLoginMode ? 'Увійти' : 'Зареєструватися'),
                  ),
                const SizedBox(height: 12),

                if (!_isLoading)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isLoginMode = !_isLoginMode;
                        _isResendButtonDisabled = false;
                      });
                    },
                    child: Text(
                      _isLoginMode
                          ? 'Створити новий акаунт'
                          : 'Я вже маю акаунт',
                    ),
                  ),
                SizedBox(height: 12),
                ElevatedButton.icon(
                  icon: Image.asset(
                    "assets/images/google/dark.png",
                    height: 24,
                  ),
                  onPressed: _signInWithGoogle,
                  label: const Text(
                    "Увійти через Google",
                    style: TextStyle(fontSize: 18),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 15, vertical: 17),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(6)),
                    ),
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    shadowColor: Theme.of(context).colorScheme.outline,
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _email_validator(String? v) {
    if (v == null || v.trim().isEmpty) {
      return 'Поле email не може бути порожнім';
    } else if (!v.trim().contains("@")) {
      return 'email повинен містити \'@\' символ';
    }
    return null;
  }

  String? _password_validator(String? v) {
    if (v == null || v.trim().isEmpty) {
      return 'Поле з паролем не може бути порожнім';
    } else if (v.trim().length < 6) {
      return 'Пароль повинен містити що найменше 6 символів';
    }
    return null;
  }
}
