import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;

  ThemeProvider({bool isDarkMode = true}) : _isDarkMode = isDarkMode;

  bool get isDarkMode => _isDarkMode;
  set isDarkMode(bool value) {
    _isDarkMode = value;
    notifyListeners();
  }

  ThemeData get themeData => _isDarkMode ? ThemeData.dark() : ThemeData.light();

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }
}