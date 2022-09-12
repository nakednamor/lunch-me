import 'dart:io';

import 'package:lunch_me/data/tables.dart';

class RecipeModel {
  String name;
  Source type;
  String? url;
  String? thumbnailUrl;
  File? thumbnailFile;
  List<File> photos = [];
  List<int> tagIds = [];

  RecipeModel(this.name, this.type);
}
