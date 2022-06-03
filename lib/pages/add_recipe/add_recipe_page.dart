import 'package:flutter/material.dart';
import 'package:lunch_me/data/tables.dart';

class AddRecipePage extends StatefulWidget {
  const AddRecipePage({super.key});

  @override
  State<AddRecipePage> createState() => _AddRecipePageState();
}

class _AddRecipePageState extends State<AddRecipePage> {
  final _formKey = GlobalKey<FormState>();

  Source? _recipeType = Source.web;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Add recipe"), // TODO global string
        ),
        body: Column(children: [
          Expanded(
              child: Padding(
            padding: const EdgeInsets.all(16),
            child: TextFormField(
              validator: (String? value) {
                if (value == null || value.isEmpty) {
                  return 'Should not be empty!'; // TODO validation + messages
                }
                return null;
              },
              decoration: const InputDecoration(
                border: UnderlineInputBorder(),
//                    labelText: AppLocalizations.of(context)!.addTagGroup,
                labelText: "Recipe name", // TODO global string
              ),
              onSaved: (String? value) async {},
            ),
          )),
          Row(
            children: [
              Radio<Source>(
                  value: Source.web,
                  groupValue: _recipeType,
                  onChanged: (Source? type) {
                    setState(() {
                      _recipeType = type;
                    });
                  }),
              const Text("Web"),
              Radio<Source>(
                  value: Source.photo,
                  groupValue: _recipeType,
                  onChanged: (Source? type) {
                    setState(() {
                      _recipeType = type;
                    });
                  }),
              const Text("Photo"),
              Radio<Source>(
                  value: Source.video,
                  groupValue: _recipeType,
                  onChanged: (Source? type) {
                    setState(() {
                      _recipeType = type;
                    });
                  }),
              const Text("Video"),
              Radio<Source>(
                  value: Source.memory,
                  groupValue: _recipeType,
                  onChanged: (Source? type) {
                    setState(() {
                      _recipeType = type;
                    });
                  }),
              const Text("Memory"),
            ],
          ),
          Row(children: [
            Visibility(
              visible: _showImagePicker(),
              child: Expanded(
                  child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextFormField(
                  validator: (String? value) {
                    if (value == null || value.isEmpty) {
                      return 'Should not be empty!'; // TODO validation + messages
                    }
                    return null;
                  },
                  decoration: const InputDecoration(
                    border: UnderlineInputBorder(),
//                    labelText: AppLocalizations.of(context)!.addTagGroup,
                    labelText: "Recipe URL", // TODO global string
                  ),
                  onSaved: (String? value) async {},
                ),
              )),
            ),
            Visibility(
              visible: !_showImagePicker(),
              child: ElevatedButton(
                onPressed: () {
                  print("button pressed");
                },
                child: const Text('image'),
              ),
            ),
          ]),
          Row(children: [
            ElevatedButton(
              onPressed: () {
                print("button pressed");
              },
              child: const Text('thumbnail'),
            ),
            Expanded(
                child: Padding(
              padding: const EdgeInsets.all(16),
              child: TextFormField(
                validator: (String? value) {
                  if (value == null || value.isEmpty) {
                    return 'Should not be empty!'; // TODO validation + messages
                  }
                  return null;
                },
                decoration: const InputDecoration(
                  border: UnderlineInputBorder(),
//                    labelText: AppLocalizations.of(context)!.addTagGroup,
                  labelText: "or from URL", // TODO global string
                ),
                onSaved: (String? value) async {},
              ),
            )),
          ]),
          ElevatedButton(
            onPressed: () {
              print("button pressed");
            },
            child: const Text('Add recipe'),
          ),
        ]));
  }

  bool _showImagePicker() {
    return _recipeType == Source.web || _recipeType == Source.video;
  }
}
