import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lunch_me/util/image_util.dart';
import 'package:lunch_me/util/recipe_change_notifier.dart';
import 'package:path/path.dart';
import 'package:provider/provider.dart';
import 'package:random_string/random_string.dart';

import '../../data/database.dart';

class EditRecipesPage extends StatelessWidget {
  EditRecipesPage({Key? key}) : super(key: key);

  final ImagePicker _imagePicker = ImagePicker();
  late final MyDatabase database;

  String? _imagePhoto;

  @override
  Widget build(BuildContext context) {
    database = Provider.of<MyDatabase>(context, listen: false);
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.titleEditRecipes),
      ),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(AppLocalizations.of(context)!.navigationBack),
          ),
          ElevatedButton(
              onPressed: () {
                _pickImage(ImageSource.gallery);
              },
              child: const Text("gallery")),
          ElevatedButton(
              onPressed: () {
                _pickImage(ImageSource.camera);
              },
              child: const Text("camera")),
          Consumer<RecipeChangeNotifier>(builder: (context, notifier, child) {
            return ElevatedButton(
                onPressed: () {
                  _createRecipe();
                  notifier.recipesChanged();
                },
                child: const Text("create new recipe"));
          })
        ],
      ),
    );
  }

  _pickImage(ImageSource source) async {
    final XFile? pickedFile = await _imagePicker.pickImage(
      source: source,
      imageQuality: 30, // TODO which value to choose ???
    );

    if (pickedFile != null) {
      var imageDirectory = await getImageDirectory();

      var fileExtension = extension(pickedFile.name);
      var imageName = randomAlphaNumeric(10);
      var fullImageName = '$imageName$fileExtension';
      var newFile = join(imageDirectory.path, fullImageName);
      pickedFile.saveTo(newFile);

      _imagePhoto = fullImageName;

      Fluttertoast.showToast(
          msg: "saved file $newFile", toastLength: Toast.LENGTH_SHORT, gravity: ToastGravity.BOTTOM, timeInSecForIosWeb: 1, backgroundColor: Colors.red, textColor: Colors.white, fontSize: 16.0);
    }
  }

  _createRecipe() async {
    var recipeName = randomAlpha(10);
    await database.createRecipe('A-$recipeName', _imagePhoto);
    Fluttertoast.showToast(
        msg: 'recipe created: $recipeName  - $_imagePhoto',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0);
  }
}
