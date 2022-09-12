import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:lunch_me/data/dao/tag_dao.dart' as tag_dao; // TODO workaround unambigous imports
import 'package:lunch_me/data/database.dart';
import 'package:lunch_me/util/recipe_manager.dart';
import 'package:lunch_me/widgets/custom_loader.dart';
import 'package:lunch_me/widgets/error_message.dart';
import 'package:provider/provider.dart';


class EditableTagGroupList extends StatefulWidget {
  const EditableTagGroupList({super.key});

  @override
  State<EditableTagGroupList> createState() => _EditableTagGroupListState();
}

class _EditableTagGroupListState extends State<EditableTagGroupList> {
  late final RecipeManager recipeManager;
  late final Stream<List<tag_dao.TagGroupWithTags>> _watchTagGroupsWithTags;
  late final Locale locale;

  void initializeData() {
    recipeManager = Provider.of<RecipeManager>(context, listen: false);
    _watchTagGroupsWithTags = recipeManager.watchAllTagsWithGroups();
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

    final List<tag_dao.TagGroupWithTags> tagGroupsWithTags = snapshot.data!;
    return ListView(
      scrollDirection: Axis.vertical,
      shrinkWrap: true,
      children: tagGroupsWithTags.map<Widget>((tag_dao.TagGroupWithTags tagGroupWithTags) {
        return _buildTagGroupRow(tagGroupWithTags);
      }).toList(),
    );
  }

  Widget _buildTagGroupRow(tag_dao.TagGroupWithTags tagGroupWithTags) {
    final tagGroupFormKey = GlobalKey<FormState>();

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
                await recipeManager.deleteTagGroup(tagGroupWithTags.tagGroup.id);
              },
            ),
            Wrap(
              children: [
                ...tagGroupWithTags.tags.map<Widget>((Tag tag) {
                  return Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Chip(
                      label: Text(tag.label),
                      backgroundColor: Colors.blueGrey.withAlpha(50),
                      onDeleted: () async {
                        await recipeManager.deleteTag(tag.id);
                      },
                    ),
                  );
                }).toList(),
                Form(
                  key: tagGroupFormKey,
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
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
                            await recipeManager.addTag(tagGroupWithTags.tagGroup.id, value);
                            tagGroupFormKey.currentState?.reset();
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
                          if (tagGroupFormKey.currentState != null && tagGroupFormKey.currentState!.validate()) {
                            tagGroupFormKey.currentState?.save();
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
    return StreamBuilder<List<tag_dao.TagGroupWithTags>>(
        stream: _watchTagGroupsWithTags,
        builder: (BuildContext context, AsyncSnapshot tagsSnapshot) {
          return tagsSnapshot.connectionState == ConnectionState.waiting ? buildCustomLoader() : _buildTagGroupListView(tagsSnapshot);
        });
  }
}
