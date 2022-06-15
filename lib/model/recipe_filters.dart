import 'dart:collection';

import 'package:flutter/material.dart';

class RecipeFilters extends ChangeNotifier {
  final List<int> _tagIds = [];

  UnmodifiableListView<int> get tagIds => UnmodifiableListView(_tagIds);

  void setTagFilters(List<int> tagIds) {
    _tagIds.clear();
    _tagIds.addAll(tagIds);
    notifyListeners();
  }
}
