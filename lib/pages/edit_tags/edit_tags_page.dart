import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:lunch_me/data/database.dart';
import 'package:lunch_me/data/dao/tag_dao.dart';
import 'package:lunch_me/data/dao/taggroup_dao.dart';
import 'package:provider/provider.dart';

class EditTagsPage extends StatefulWidget {
  const EditTagsPage({Key? key}) : super(key: key);

  @override
  _EditTagsPageState createState() => _EditTagsPageState();
}

class _EditTagsPageState extends State<EditTagsPage> {
  final _tagGroupFormKey = GlobalKey<FormState>();
  final _deleteTagGroupFormKey = GlobalKey<FormState>(); // temp
  late final MyDatabase database;
  late TagGroupDao tagGroupDao;
  late TagDao tagDao;

  void initializeData() {
    database = Provider.of<MyDatabase>(context, listen: false);
    tagGroupDao = database.tagGroupDao;
    tagDao = database.tagDao;
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
                            return 'Should not be empty!'; // TODO validate
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          border: const UnderlineInputBorder(),
                          labelText: AppLocalizations.of(context)!.addTagGroup,
                        ),
                        onSaved: (String? value) async {
                          if (value != null) {
                            final newTagGroup =
                                await tagGroupDao.addTagGroup(value);

                            debugPrint("new tag group id");
                            debugPrint(newTagGroup.id.toString());

                            // TODO temporary add a new tag so deletion is possible
                            final newTag = await tagDao.addTag(
                                newTagGroup.id, "initial tag");
                            debugPrint(newTag.id.toString());
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
          // Just a temporary helper to remove tag groups by name
          Form(
              key: _deleteTagGroupFormKey,
              child:
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Expanded(
                    child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextFormField(
                    validator: (String? value) {
                      if (value == null || value.isEmpty) {
                        return 'Should not be empty!'; // TODO validate
                      }
                      return null;
                    },
                    decoration: const InputDecoration(
                      border: UnderlineInputBorder(),
                      labelText:
                          "Remove tag group by id", // TODO this is just temporary
                    ),
                    onSaved: (String? value) async {
                      if (value != null) {
                        final tagGroupId = int.parse(value);

                        debugPrint('TagGroupId to delete: $tagGroupId');
                        await tagGroupDao.deleteTagGroup(tagGroupId);
                      }
                    },
                  ),
                )),
                IconButton(
                    iconSize: 38,
                    padding: const EdgeInsets.only(left: 0),
                    icon: const Icon(
                      Icons.delete,
                    ),
                    onPressed: () {
                      if (_deleteTagGroupFormKey.currentState != null &&
                          _deleteTagGroupFormKey.currentState!.validate()) {
                        _deleteTagGroupFormKey.currentState?.save();
                      }
                    }),
              ])),
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
