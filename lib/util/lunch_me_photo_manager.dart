import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:lunch_me/util/image_util.dart';
import 'package:path/path.dart';

class LunchMePhotoManager {
  late ImagePicker _picker;

  static const int lunchmeImageQuality = 30;
  static const double lunchmeMaxWidth = 300;

  static final LunchMePhotoManager _instance = LunchMePhotoManager._internal();

  LunchMePhotoManager._internal();

  factory LunchMePhotoManager(ImagePicker imagePicker) {
    _instance._picker = imagePicker;
    return _instance;
  }

  // take a photo with the camera - photo is stored in application cache directory
  Future<File?> takePhotoWithCamera() async {
    return await _getImage(ImageSource.camera);
  }

  // pick a photo from the gallery - photo is stored in application cache directory
  Future<File?> selectPhotoFromGallery() async {
    return await _getImage(ImageSource.gallery);
  }

  // saves the given photo to the image directory using the provided name and returns the copied file
  Future<File> savePhotoToImageDirectory(File photo, String imageName) async {
    var imageDirectory = await getImageDirectory();
    var finalImagePath = _getFinalImagePath(imageDirectory, imageName);
    await photo.copy(finalImagePath);

    return File(finalImagePath);
  }

  // deletes the photo with the given name from the image directory
  Future<void> deletePhoto(String photoName) async {
    var imageDirectory = await getImageDirectory();
    var finalImagePath = _getFinalImagePath(imageDirectory, photoName);
    File file = File(finalImagePath);
    await file.delete();
  }

  String _getFinalImagePath(Directory directory, String fileName) {
    return join(directory.path, fileName);
  }

  Future<File?> _getImage(ImageSource source) async {
    var image = await _getXImage(source);
    if (image == null) {
      return null;
    }

    return File(image.path);
  }

  Future<XFile?> _getXImage(ImageSource source) async {
    return await _picker.pickImage(source: source, maxWidth: lunchmeMaxWidth, imageQuality: lunchmeImageQuality);
  }
}
