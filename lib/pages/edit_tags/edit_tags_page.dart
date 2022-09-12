import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:lunch_me/util/recipe_manager.dart';
import 'package:lunch_me/pages/edit_tags/widgets/editable_tag_group_list.dart';
import 'package:provider/provider.dart';

class EditTagsPage extends StatefulWidget {
  const EditTagsPage({super.key});

  @override
  State<EditTagsPage> createState() => _EditTagsPageState();
}

class _EditTagsPageState extends State<EditTagsPage> {
  final _tagGroupFormKey = GlobalKey<FormState>();
  late final RecipeManager recipeManager;

  void initializeData() {
    recipeManager = Provider.of<RecipeManager>(context, listen: false);
  }

  @override
  void didChangeDependencies() {
    initializeData();

    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.titleEditTags),
      ),
      body: Column(
        children: [
          Form(
              key: _tagGroupFormKey,
              child: Column(
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
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
                        decoration: InputDecoration(
                          border: const UnderlineInputBorder(),
                          labelText: AppLocalizations.of(context)!.addTagGroup,
                        ),
                        onSaved: (String? value) async {
                          if (value != null) {
                            await recipeManager.addTagGroup(value);
                            _tagGroupFormKey.currentState?.reset();
                          }
                        },
                      ),
                    )),
                    IconButton(
                        iconSize: 38,
                        padding: const EdgeInsets.only(left: 0),
                        icon: const Icon(
                          Icons.add_task,
                        ),
                        onPressed: () {
                          if (_tagGroupFormKey.currentState != null &&
                              _tagGroupFormKey.currentState!.validate()) {
                            _tagGroupFormKey.currentState?.save();
                          }
                        }),
                  ]),
                ],
              )),
          const Flexible(child: EditableTagGroupList()),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(AppLocalizations.of(context)!.navigationBack),
          )
        ],
      ),
    );
  }
}
