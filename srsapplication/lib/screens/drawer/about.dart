import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(centerTitle: true, title: Text("Про додаток")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              "assets/images/icon_dp.png",
              fit: BoxFit.cover,
              width: 120,
            ),
            Container(
              child: Text(
                "Додаток було створено за допомогою Flutter та Firebase, за для надавання користувачам можливості вивчати іноземні слова за допомогою флеш-карт",
                textAlign: TextAlign.center,
              ),
              width: 300,
              height: 200,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.brown.shade700,
                borderRadius: BorderRadius.all(Radius.circular(20)),
                border: Border.all(color: Colors.brown.shade900, width: 3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
