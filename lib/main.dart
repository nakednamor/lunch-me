import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import 'data/database.dart';

void main() {
  runApp(
    Provider<MyDatabase>(
      create: (context) => MyDatabase(),
      child: const MyApp(),
      dispose: (context, db) => db.close(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lunch Me!',
      onGenerateTitle: (BuildContext context) =>
          AppLocalizations.of(context)!.title,
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.cyan,
      ),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''), // English, no country code
        Locale('de', ''), // German, no country code
      ],
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late List<TagGroupWithTags> tagGroupsWithTags;
  int count = 0;

  @override
  Widget build(BuildContext context) {
    final database = Provider.of<MyDatabase>(context);

    final Locale appLocale = Localizations.localeOf(context);

    var tagGroupsWithTagsFuture = database.getAllTagsWithGroups(appLocale);

    tagGroupsWithTagsFuture.then((tagGroupsWithTags) {
      setState(() {
        this.tagGroupsWithTags = tagGroupsWithTags;
        this.count = tagGroupsWithTags.length;
      });
    });
    // tagGroupsWithTags.then((value) {
    //   for (var tagGroupWithTags in value) {
    //     debugPrint("group: ${tagGroupWithTags.tagGroup}");
    //     for (var tag in tagGroupWithTags.tags) {
    //       debugPrint("tag: $tag");
    //     }
    //   }
    // });

    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.greeting),
      ),
      body: getTagListView(),
    );
  }

  // Item of the ListView
  Widget tagItems(groupIndex) {
    var tagGroup = tagGroupsWithTags[groupIndex];
    int tagCount = tagGroup.tags.length;

    if(tagCount > 0) {
      return ListView.builder(
          itemCount: tagCount,
          itemBuilder: (BuildContext context, int tagIndex) {
            return Text(tagGroup.tags[tagIndex].label);
          },
        shrinkWrap: true, // TODO provide fixed size/layout
      );
    }

    return Text("no tags found in this group"); // TODO translate
  }

  ListView getTagListView() {
    return ListView.builder(
      itemCount: count,
      itemBuilder: (BuildContext context, int index) {
          return Column(
            children: [
              // The header
              Container(
                padding: const EdgeInsets.all(10),
                color: Colors.amber,
                child: Text(tagGroupsWithTags[index].tagGroup.label),
              ),

              // The first list item
              tagItems(index)
            ],
          );
        //return tagItems(index);
      },
      shrinkWrap: true, // TODO provide fixed size/layout
    );
  }
}

