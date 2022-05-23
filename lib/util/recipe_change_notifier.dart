import 'package:flutter/material.dart';

class RecipeChangeNotifier extends ChangeNotifier {
  void recipesChanged() {
    notifyListeners();
  }
}
