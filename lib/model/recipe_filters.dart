import 'dart:collection';

import 'package:flutter/material.dart';

class RecipeFilters extends ChangeNotifier {
  final List<RecipeFilter> _filterList = [];

  UnmodifiableListView<RecipeFilter> get filter => UnmodifiableListView(_filterList);

  void setFilter(List<RecipeFilter> filter) {
    _filterList.clear();
    _filterList.addAll(filter);
    notifyListeners();
  }
}

class RecipeFilter {
  final int tagGroup;
  final bool allMatch;
  final List<int> tags;

  RecipeFilter(this.tagGroup, this.allMatch, this.tags);

  @override
  int get hashCode => tagGroup.hashCode;

  @override
  bool operator ==(Object other) => other is RecipeFilter && other.runtimeType == runtimeType && other.tagGroup == tagGroup;
}
