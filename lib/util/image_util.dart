import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

const lunchMeProtocolName = 'lunchMe';
const fullLunchMeProtocol = '$lunchMeProtocolName://';
const lunchMeImageDirectoryName = 'images';

String buildImageUrl(String imagePhoto) {
  return join(fullLunchMeProtocol, imagePhoto);
}

bool isLunchMeFile(String url) {
  return url.startsWith(fullLunchMeProtocol);
}

String getLunchMeFileName(String lunchMeFile) {
  return lunchMeFile.substring(fullLunchMeProtocol.length);
}

Future<Directory> getImageDirectory() async {
  var appDirectory = await getApplicationDocumentsDirectory();
  var directoryPath = join(appDirectory.path, lunchMeImageDirectoryName);
  var imageDirectory = Directory(directoryPath);
  imageDirectory.createSync(recursive: true);
  return imageDirectory;
}
