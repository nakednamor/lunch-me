import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:lunch_me/data/tables.dart';
import 'package:lunch_me/util/recipe_manager.dart';
import 'package:lunch_me/model/recipe_model.dart';
import 'package:lunch_me/util/lunch_me_photo_manager.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

class EditRecipesPage extends StatelessWidget {
  const EditRecipesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final RecipeManager recipeManager = Provider.of<RecipeManager>(context, listen: false);
    final LunchMePhotoManager photoManager = Provider.of<LunchMePhotoManager>(context, listen: false);

    File? takenPhoto ;


    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.titleEditRecipes),
      ),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () async {
              var x = await photoManager.takePhotoWithCamera();
              if(x != null) {
                takenPhoto = x;
              }
            },
            child: const Text("camera"),
          ),
          ElevatedButton(
            onPressed: () async {
              var x = await photoManager.selectPhotoFromGallery();
              if(x != null) {
                takenPhoto = x;
              }
            },
            child: const Text("gallery"),
          ),
          ElevatedButton(
            onPressed: () {
              var uuid = const Uuid();
              var name = uuid.v4();
              var url = "http://recipes-lunch.me/${uuid.v4()}";
              var model = RecipeModel.newRecipe(name, Source.web);
              model.url = url;
              model.thumbnailFile = takenPhoto;

              recipeManager.createRecipe(model);
            },
            child: const Text("create web recipe with image url"),
          ),
        ],
      ),
    );
  }
}
