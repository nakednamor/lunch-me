import 'dart:io';

import 'package:lunch_me/data/tables.dart';

class RecipeModel {
  int? id;
  String name;
  Source type;
  String? url;
  String? thumbnailUrl;
  File? thumbnailFile;
  List<File> photos = [];
  List<int> tagIds = [];

  RecipeModel.newRecipe(this.name, this.type);
  RecipeModel.existingRecipe(this.id, this.name, this.type);
}
