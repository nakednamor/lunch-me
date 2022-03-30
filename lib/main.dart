import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:lunch_me/pages/edit_recipes/edit_recipes_page.dart';
import 'package:lunch_me/pages/edit_tags/edit_tags_page.dart';
import 'package:provider/provider.dart';

import 'package:lunch_me/data/database.dart';
import 'package:lunch_me/pages/home/home_page.dart';

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
          AppLocalizations.of(context)!.appTitle,
      theme: ThemeData(
        // This is the theme of your application.
        primarySwatch: Colors.cyan,
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            primary: Colors.black, // This is a custom color variable
          ),
        ),
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
      initialRoute: '/',
      routes: {
        '/': (context) => const HomePage(),
        '/edit-tags': (context) => const EditTagsPage(),
        '/edit-recipes': (context) => const EditRecipesPage(),
      },
    );
  }
}
