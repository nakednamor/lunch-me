import 'package:flow_builder/flow_builder.dart';
import 'package:flutter/material.dart';
import 'package:lunch_me/data/database.dart';
import 'package:lunch_me/pages/add_recipe/views/add_recipe_content_photo_view.dart';
import 'package:lunch_me/pages/add_recipe/views/add_recipe_image_view.dart';
import 'package:lunch_me/pages/add_recipe/views/add_recipe_name_view.dart';
import 'package:lunch_me/pages/add_recipe/views/add_recipe_type_view.dart';
import 'package:provider/provider.dart';

import 'model/recipe_info.dart';

class AddRecipePage extends StatefulWidget {
  const AddRecipePage({super.key});

  @override
  State<AddRecipePage> createState() => _AddRecipePage();
}

class _AddRecipePage extends State<AddRecipePage> {
  late FlowController<RecipeInfo> _flowController;
  late final MyDatabase database;

  @override
  void initState() {
    super.initState();
    _flowController = FlowController(const RecipeInfo());
  }

  @override
  void dispose() {
    _flowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    database = Provider.of<MyDatabase>(context, listen: false);
    return FlowBuilder<RecipeInfo>(
      controller: _flowController,
      onGeneratePages: (recipeInfo, pages) {
        return [
          const MaterialPage(child: AddRecipeNameView()),
          if (_flowController.state.name != null) const MaterialPage(child: AddRecipeTypeView()),
          if (_flowController.state.type != null) const MaterialPage(child: AddRecipeImageView()),
          if (_flowController.state.imagePhoto != null) const MaterialPage(child: AddRecipeContentPhotoView())
        ];
      },
      onComplete: (recipeInfo) async {
        await _createRecipe(recipeInfo);
        Navigator.pop(context);
      },
    );
  }

  _createRecipe(RecipeInfo recipeInfo) async {
    await database.createRecipe(recipeInfo.name!, recipeInfo.imagePhoto!, recipeInfo.contentPhoto!);
  }
}
