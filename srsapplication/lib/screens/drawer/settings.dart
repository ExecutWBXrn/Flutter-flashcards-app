import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:srsapplication/themes/themes.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          appBar: AppBar(title: Text('Налаштування'), centerTitle: true),
          body: ListView(
            children: <Widget>[
              Center(
                child: Text(
                  "Тема",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
                ),
              ),
              RadioListTile<ThemeMode>(
                title: const Text('Системна тема'),
                subtitle: const Text('Використовувати налаштування пристрою'),
                value: ThemeMode.system,
                groupValue: themeProvider.themeMode,
                onChanged: (ThemeMode? value) {
                  if (value != null) {
                    themeProvider.setThemeMode(value);
                  }
                },
              ),
              RadioListTile<ThemeMode>(
                title: const Text('Світла тема'),
                value: ThemeMode.light,
                groupValue: themeProvider.themeMode,
                onChanged: (ThemeMode? value) {
                  if (value != null) {
                    themeProvider.setThemeMode(value);
                  }
                },
              ),
              RadioListTile<ThemeMode>(
                title: const Text('Темна тема'),
                value: ThemeMode.dark,
                groupValue: themeProvider.themeMode,
                onChanged: (ThemeMode? value) {
                  if (value != null) {
                    themeProvider.setThemeMode(value);
                  }
                },
              ),
              const Divider(),
              ListTile(
                title: const Text('Поточний активний стиль:'),
                trailing: Text(
                  themeProvider.isCurrentlyDark(context) ? 'Темний' : 'Світлий',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
