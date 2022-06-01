import 'package:flow_builder/flow_builder.dart';
import 'package:flutter/material.dart';
import 'package:lunch_me/data/tables.dart';
import 'package:lunch_me/pages/add_recipe/model/recipe_info.dart';

class AddRecipeTypeView extends StatefulWidget {
  const AddRecipeTypeView({Key? key}) : super(key: key);

  @override
  State<AddRecipeTypeView> createState() => _AddRecipeTypeView();
}

class _AddRecipeTypeView extends State<AddRecipeTypeView> {

  void _nextPressed(Source type) {
    context.flow<RecipeInfo>().update((recipeInfo) => recipeInfo.copyWith(type: type));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recipe type')),
      body: Center(
        child: Column(
          children: <Widget>[
            const ElevatedButton(
              onPressed: null,
              child: Text('Website'),
            ),
            const ElevatedButton(
              onPressed: null,
              child: Text('Video'),
            ),
            ElevatedButton(
              onPressed: () {
                _nextPressed(Source.photo);
              },
              child: const Text('Photo'),
            ),
            const ElevatedButton(
              onPressed: null,
              child: Text('Memory'),
            )
          ],
        ),
      ),
    );
  }
}
