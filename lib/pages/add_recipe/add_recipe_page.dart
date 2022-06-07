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

  late final TextEditingController _recipeNameController;
  late final TextEditingController _recipeUrlController;

  late OverlayEntry _overlayEntry;
  late bool _overlayShown;

  @override
  void initState() {
    super.initState();
    _recipeNameController = TextEditingController();
    _recipeUrlController = TextEditingController();
    _overlayEntry = _createOverlayEntry();
    _overlayShown = false;
  }

  @override
  void dispose() {
    _recipeNameController.dispose();
    _recipeUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Add recipe"), // TODO global string
        ),
        body: GestureDetector(
            onTap: () {
              print("XXXXXXXXXXXX");
              if (!_overlayShown) {
                print("YYYYYY");
              } else {
                print("ZZZZZZ");
                _overlayEntry?.remove();
                _overlayShown = false;
              }
            },
            child: Container(
                height: MediaQuery.of(context).size.height,
                width: MediaQuery.of(context).size.width,
                child: Form(
                    key: _formKey,
                    child: Column(children: [
                      Expanded(
                          child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: TextFormField(
                          controller: _recipeNameController,
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
                              controller: _recipeUrlController,
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
                              if (!_overlayShown) {
                                Overlay.of(context)?.insert(_overlayEntry!);
                                _overlayShown = true;
                              } else {
                                _overlayEntry.remove();
                                _overlayShown = false;
                              }
                            },
                            child: const Text('image'),
                          ),
                        ),
                      ]),
                      Row(children: [
                        ElevatedButton(
                          onPressed: () {
                            print("button pressed");
                            if (_overlayShown) {
                              _overlayEntry.remove();
                              _overlayShown = false;
                            }
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
                          _formKey.currentState!.validate();

                          print("button pressed");
                        },
                        child: const Text('Add recipe'),
                      ),
                    ])))));
  }

  bool _showImagePicker() {
    return _recipeType == Source.web || _recipeType == Source.video;
  }

  void _showOverlay() {}

  OverlayEntry _createOverlayEntry() {
    return OverlayEntry(builder: (context) {
      return Positioned(
        left: MediaQuery.of(context).size.width * 0.1,
        top: MediaQuery.of(context).size.height * 0.3,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
              padding: EdgeInsets.all(MediaQuery.of(context).size.height * 0.02),
              //width: MediaQuery.of(context).size.width * 0.8,
              //height: MediaQuery.of(context).size.height * 0.1,
              color: Colors.pink.withOpacity(0.3),
              child: Column(
                children: [
                  ElevatedButton(onPressed: () {}, child: const Text("AAAAAA")),
                  ElevatedButton(onPressed: () {}, child: const Text("BBBB")),
                ],
              )),
        ),
      );
    });
  }
}
