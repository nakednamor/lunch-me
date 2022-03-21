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

                            // TODO temporary add a new tag so deletion is possible
                            // TBD when tag crud is there
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
                  // // Just a temporary helper to remove tag groups by name (should be with X icon instead)
                  // Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  //   Expanded(
                  //       child: Padding(
                  //     padding: const EdgeInsets.all(16),
                  //     child: TextFormField(
                  //       validator: (String? value) {
                  //         if (value == null || value.isEmpty) {
                  //           return 'Should not be empty!'; // TODO validate
                  //         }
                  //         return null;
                  //       },
                  //       decoration: const InputDecoration(
                  //         border: UnderlineInputBorder(),
                  //         labelText:
                  //             "Remove tag group", // TODO this is just temporary
                  //       ),
                  //       onSaved: (String? value) async {
                  //         if (value != null) {
                  //           final allTagGroups =
                  //               await tagGroupDao.getAllTagGroups();

                  //               allTagGroups.firstWhere((tagGroup) => tagGroup.)
                  //           //await tagGroupDao.deleteTagGroup(value);
                  //         }
                  //       },
                  //     ),
                  //   )),
                  //   IconButton(
                  //       iconSize: 38,
                  //       padding: const EdgeInsets.only(left: 0),
                  //       icon: const Icon(
                  //         Icons.remove,
                  //       ),
                  //       onPressed: () {
                  //         if (_tagGroupFormKey.currentState != null &&
                  //             _tagGroupFormKey.currentState!.validate()) {
                  //           _tagGroupFormKey.currentState?.save();
                  //         }
                  //       }),
                  // ])
                ],
              )),
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
