import 'dart:io';

import 'package:lunch_me/util/lunch_me_photo_manager.dart';
import 'package:mockito/mockito.dart';

class LunchMePhotoManagerMock extends Mock implements LunchMePhotoManager {
  @override
  Future<File> getPhotoFile(String? photoName) => super.noSuchMethod(Invocation.method(#getPhotoFile, [photoName]), returnValue: Future.value(File('tmp/some-file.txt')));
}
