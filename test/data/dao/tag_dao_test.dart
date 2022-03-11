import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lunch_me/data/dao/tag_dao.dart';

import '../flutter_test_config.dart';

void main() {
  late TagDao dao;

  setUp(() async {
    debugPrint('test: setup started');
    dao = testDatabase.tagDao;
    debugPrint('test: setup finished');
  });

  tearDown(() async {
    debugPrint('test: teardown started');
    debugPrint('test: teardown finished');
  });

  test('should throw exception when new tag name is empty', () async {});
  test('should throw exception when new tag name > 50 chars', () async {});
  test('should add new tag at the last position within tag-group', () async {});
  test('should add new tag with same value for all languages', () async {});
  test('should throw exception when adding tag with existing name', () async {});
  test('should throw exception when tag-group not found by given id', () async {});

  test('should rename tag', () async {});
  test('rename tag should throw exception when name already exists', () async {});
  test('rename tag should throw exception when name is empty', () async {});
  test('rename tag should throw exception when name > 50 chars', () async {});

  test('should allow changing order of tag', () async {});
  test('reordering should throw exception when there is no tag with given id', () async {});
  test('reordering should throw exception when new position is negative', () async {});

  test('should remove tag properly', () async {});
  test('removing tag should throw exception when there is no tag with given id', () async {});



}
