import 'dart:async';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lunch_me/data/database.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

const String testDatabasePath = 'test_resources/data/test_lunch_me_db';
const String testDatabaseTemporaryFileName = 'app_test.db';

late MyDatabase testDatabase;
late File testDatabaseFile;

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  setUp(() async {
    debugPrint('top-level: setup started');

    await _deleteTemporaryDatabaseFile();

    var databaseFile = await _prepareTestDatabaseFile();

    testDatabase = MyDatabase.testDb(NativeDatabase(
      databaseFile,
      logStatements: true,
    ));

    debugPrint('top-level: setup finished');
  });

  tearDown(() async {
    debugPrint('top-level: teardown started');
    debugPrint('top-level: closing test database');
    await testDatabase.close();
    await _deleteTemporaryDatabaseFile();
    debugPrint('top-level: teardown finished');
  });

  await testMain();
}

Future<void> _deleteTemporaryDatabaseFile() async {
  var file = await _getTemporaryDatabaseFile();

  if (await file.exists()) {
    debugPrint('top-level: going to delete temporary file ${file.path}');
    await file.delete();
    debugPrint('top-level: temporary file ${file.path} deleted');
  } else {
    debugPrint('top-level: temporary file ${file.path} does not exist');
  }
}

Future<File> _getTemporaryDatabaseFile() async {
  final tempDirectory = await getTemporaryDirectory();
  var file = File(join(tempDirectory.path, testDatabaseTemporaryFileName));
  return file;
}

Future<File> _prepareTestDatabaseFile() async {
  testDatabaseFile = await _getTemporaryDatabaseFile();
  final file = File(testDatabasePath);

  if (!await testDatabaseFile.exists()) {
    debugPrint(
        'top-level: temporary file ${file.path} does not exist - copying content from ${file.path}');
    file.copy(testDatabaseFile.path);
  }
  return testDatabaseFile;
}
