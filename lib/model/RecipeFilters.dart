import 'dart:collection';

import 'package:flutter/material.dart';

class RecipeFilters extends ChangeNotifier {
  final List<int> _tagIds = [];

  UnmodifiableListView<int> get tagIds => UnmodifiableListView(_tagIds);

  void addTagFilter(int id) {
    _tagIds.add(id);
    notifyListeners();
  }

  void removeTagFilter(int id) {
    _tagIds.removeWhere((element) => element == id);
    notifyListeners();
  }
}
