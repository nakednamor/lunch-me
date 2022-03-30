import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:lunch_me/data/dao/taggroup_dao.dart'
    as tag_group_dao; // TODO workaround unambigous imports
import 'package:lunch_me/data/dao/tag_dao.dart'
    as tag_dao; // TODO workaround unambigous imports
import 'package:provider/provider.dart';

import 'package:lunch_me/data/database.dart';
import 'package:lunch_me/widgets/error_message.dart';
import 'package:lunch_me/widgets/custom_loader.dart';

class EditableTagGroupList extends StatefulWidget {
  const EditableTagGroupList({Key? key}) : super(key: key);

  @override
  _EditableTagGroupListState createState() => _EditableTagGroupListState();
}

class _EditableTagGroupListState extends State<EditableTagGroupList> {
  late final Stream<List<TagGroupWithTags>> _watchTagGroupsWithTags;
  late final MyDatabase database;
  late final Locale locale;
  late tag_group_dao.TagGroupDao _tagGroupDao;
  late tag_dao.TagDao _tagDao;

  void initializeData() {
    database = Provider.of<MyDatabase>(context, listen: false);
    locale = Localizations.localeOf(context);
    _watchTagGroupsWithTags = database.watchAllTagsWithGroups(locale);
    _tagGroupDao = database.tagGroupDao;
    _tagDao = database.tagDao;
  }

  @override
  void didChangeDependencies() {
    initializeData();

    super.didChangeDependencies();
  }

  Widget _buildTagGroupListView(AsyncSnapshot snapshot) {
    if (!snapshot.hasData) {
      return errorMessage(AppLocalizations.of(context)!.errorNoTagsFound);
    }

    final List<TagGroupWithTags> _tagGroupsWithTags = snapshot.data!;
    return ListView(
      scrollDirection: Axis.vertical,
      shrinkWrap: true,
      children:
          _tagGroupsWithTags.map<Widget>((TagGroupWithTags tagGroupWithTags) {
        return _buildTagGroupRow(tagGroupWithTags);
      }).toList(),
    );
  }

  Widget _buildTagGroupRow(TagGroupWithTags tagGroupWithTags) {
    final _tagGroupFormKey = GlobalKey<FormState>();

    return Container(
        margin: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextButton(
              child: Row(children: [
                Text(tagGroupWithTags.tagGroup.label),
                const Icon(
                  Icons.delete,
                  size: 24.0,
                ),
              ]),
              onPressed: () async {
                await _tagGroupDao
                    .deleteTagGroup(tagGroupWithTags.tagGroup.tagGroup);
              },
            ),
            Wrap(
              children: [
                ...tagGroupWithTags.tags.map<Widget>((LocalizedTag tag) {
                  return Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Chip(
                      label: Text(tag.label),
                      backgroundColor: Colors.blueGrey.withAlpha(50),
                      onDeleted: () async {
                        await _tagDao.deleteTag(tag.tag);
                      },
                    ),
                  );
                }).toList(),
                Form(
                  key: _tagGroupFormKey,
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
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
                              labelText: AppLocalizations.of(context)!.addTag,
                            ),
                            onSaved: (String? value) async {
                              if (value != null) {
                                await _tagDao.addTag(
                                    tagGroupWithTags.tagGroup.tagGroup, value);
                                _tagGroupFormKey.currentState?.reset();
                              }
                            },
                          ),
                        )),
                        IconButton(
                            iconSize: 24,
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
                )
              ],
            )
          ],
        ));
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<TagGroupWithTags>>(
        stream: _watchTagGroupsWithTags,
        builder: (BuildContext context, AsyncSnapshot tagsSnapshot) {
          return tagsSnapshot.connectionState == ConnectionState.waiting
              ? buildCustomLoader()
              : _buildTagGroupListView(tagsSnapshot);
        });
  }
}
