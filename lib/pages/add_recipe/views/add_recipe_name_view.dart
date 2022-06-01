import 'package:flow_builder/flow_builder.dart';
import 'package:flutter/material.dart';
import 'package:lunch_me/pages/add_recipe/model/recipe_info.dart';

class AddRecipeNameView extends StatefulWidget {
  const AddRecipeNameView({Key? key}) : super(key: key);

  @override
  State<AddRecipeNameView> createState() => _AddRecipeNameView();
}

class _AddRecipeNameView extends State<AddRecipeNameView> {
  var _name = '';

  void _nextPressed() {
    context.flow<RecipeInfo>().update((recipeInfo) => recipeInfo.copyWith(name: _name));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recipe name')),
      body: Center(
        child: Column(
          children: <Widget>[
            TextField(
              onChanged: (value) => setState(() => _name = value),
              decoration: const InputDecoration(
                labelText: 'Recipe name',
                hintText: 'my new recipe',
              ),
              keyboardType: TextInputType.name,
            ),
            ElevatedButton(
              onPressed: () {
                if (_name.isNotEmpty) {
                  _nextPressed();
                }
              },
              child: const Text('Next'),
            )
          ],
        ),
      ),
    );
  }
}
