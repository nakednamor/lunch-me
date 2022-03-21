import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import 'package:lunch_me/data/database.dart';
import 'package:lunch_me/data/dao/taggroup_dao.dart'
    as tgd; // unambigous import workaround (database in dao)
import 'package:lunch_me/widgets/error_message.dart';
import 'package:lunch_me/widgets/custom_loader.dart';

class TagGroupList extends StatefulWidget {
  const TagGroupList({Key? key}) : super(key: key);

  @override
  _TagGroupListState createState() => _TagGroupListState();
}

class _TagGroupListState extends State<TagGroupList> {
  late final Stream<List<TagGroupWithTags>> _watchTagGroupsWithTags;
  late tgd.TagGroupDao _tagGroupDao;
  late final MyDatabase database;
  late final Locale locale;

  final List<String> _selectedTags = <String>[];

  void initializeData() {
    database = Provider.of<MyDatabase>(context, listen: false);
    locale = Localizations.localeOf(context);
    _watchTagGroupsWithTags = database.watchAllTagsWithGroups(locale);
    _tagGroupDao = database.tagGroupDao;
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
    return Container(
        margin: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(tagGroupWithTags.tagGroup.label),
            Wrap(
              children: tagGroupWithTags.tags.map<Widget>((LocalizedTag tag) {
                return Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Row(
                    children: [
                      FilterChip(
                        label: Text(tag.label),
                        selected: _selectedTags.contains(tag.label),
                        backgroundColor: Colors.blueGrey.withAlpha(50),
                        selectedColor: Colors.lime,
                        onSelected: (bool value) {
                          setState(() {
                            if (value) {
                              _selectedTags.add(tag.label);
                            } else {
                              _selectedTags.removeWhere((String label) {
                                return label == tag.label;
                              });
                            }
                          });
                        },
                      ),
                      IconButton(
                          // TODO this is only temporary to allow removing taggroups somewhere
                          iconSize: 38,
                          padding: const EdgeInsets.only(left: 0),
                          icon: const Icon(
                            Icons.delete,
                          ),
                          onPressed: () async {
                            final tagGroupId = tagGroupWithTags.tagGroup.id;
                            debugPrint(tagGroupId.toString());
                            await _tagGroupDao.deleteTagGroup(
                                tagGroupId); // tagGroupWithTags.tagGroup.id
                          })
                    ],
                  ),
                );
              }).toList(),
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
