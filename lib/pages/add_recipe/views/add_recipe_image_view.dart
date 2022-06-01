import 'package:flow_builder/flow_builder.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lunch_me/pages/add_recipe/model/recipe_info.dart';
import 'package:lunch_me/util/image_util.dart';
import 'package:path/path.dart' as path;
import 'package:random_string/random_string.dart';

class AddRecipeImageView extends StatefulWidget {
  const AddRecipeImageView({Key? key}) : super(key: key);

  @override
  State<AddRecipeImageView> createState() => _AddRecipeImageView();
}

class _AddRecipeImageView extends State<AddRecipeImageView> {
  final ImagePicker _imagePicker = ImagePicker();

  void _nextPressed(String image) {
    context.flow<RecipeInfo>().update((recipeInfo) => recipeInfo.copyWith(imagePhoto: image));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pick the icon image')),
      body: Center(
        child: Column(
          children: <Widget>[
            ElevatedButton(
                onPressed: () async {
                  var image = await _pickImage(ImageSource.gallery);
                  if (image != null) {
                    _nextPressed(image);
                  }
                },
                child: const Text("gallery")),
            ElevatedButton(
                onPressed: () async {
                  var image = await _pickImage(ImageSource.camera);
                  if (image != null) {
                    _nextPressed(image);
                  }
                },
                child: const Text("camera")),
          ],
        ),
      ),
    );
  }

  Future<String?> _pickImage(ImageSource source) async {
    final XFile? pickedFile = await _imagePicker.pickImage(
      source: source,
      imageQuality: 30, // TODO which value to choose ???
    );

    if (pickedFile == null) {
      return null;
    }

    var imageDirectory = await getImageDirectory();

    var fileExtension = path.extension(pickedFile.name);
    var imageName = randomAlphaNumeric(10);
    var fullImageName = '$imageName$fileExtension';
    var newFile = path.join(imageDirectory.path, fullImageName);
    pickedFile.saveTo(newFile);

    return fullImageName;
  }
}
