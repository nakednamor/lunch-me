import 'dart:io' as io;
import 'dart:typed_data';

import 'package:file/file.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:lunch_me/util/image_util.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class LunchMeCacheManager implements BaseCacheManager {
  static const key = 'lunchMeCustomCache';
  static CacheManager instance = CacheManager(
    Config(key, stalePeriod: const Duration(days: 1000), maxNrOfCacheObjects: 20, repo: JsonCacheInfoRepository(databaseName: key), fileService: LunchMeCacheFileService()),
  );

  static final LunchMeCacheManager _lunchMeCacheManager = LunchMeCacheManager._internal();

  factory LunchMeCacheManager(){
    return _lunchMeCacheManager;
  }

  LunchMeCacheManager._internal();

  @override
  Future<void> dispose() {
    return instance.dispose();
  }

  @override
  Future<FileInfo> downloadFile(String url, {String? key, Map<String, String>? authHeaders, bool force = false}) {
    return instance.downloadFile(url, key: key, authHeaders: authHeaders, force: force);
  }

  @override
  Future<void> emptyCache() {
    return instance.emptyCache();
  }

  @Deprecated("deprecated by BaseCacheManager")
  @override
  Stream<FileInfo> getFile(String url, {String? key, Map<String, String>? headers}) {
    return instance.getFile(url, key: key, headers: headers);
  }

  @override
  Future<FileInfo?> getFileFromCache(String key, {bool ignoreMemCache = false}) {
    return instance.getFileFromCache(key, ignoreMemCache: ignoreMemCache);
  }

  @override
  Future<FileInfo?> getFileFromMemory(String key) {
    return instance.getFileFromMemory(key);
  }

  @override
  Stream<FileResponse> getFileStream(String url, {String? key, Map<String, String>? headers, bool withProgress = false}) {
    return instance.getFileStream(url, key: key, headers: headers, withProgress: withProgress);
  }

  @override
  Future<void> removeFile(String key) {
    return instance.removeFile(key);
  }

  @override
  Future<File> getSingleFile(String url, {String? key, Map<String, String>? headers}) {
    return instance.getSingleFile(url, key: key, headers: headers);
  }

  @override
  Future<File> putFile(String url, Uint8List fileBytes, {String? key, String? eTag, Duration maxAge = const Duration(days: 30), String fileExtension = 'file'}) {
    return instance.putFile(url, fileBytes, key: key, eTag: eTag, maxAge: maxAge, fileExtension: fileExtension);
  }

  @override
  Future<File> putFileStream(String url, Stream<List<int>> source, {String? key, String? eTag, Duration maxAge = const Duration(days: 30), String fileExtension = 'file'}) {
    return instance.putFileStream(url, source, key: key, eTag: eTag, maxAge: maxAge, fileExtension: fileExtension);
  }
}

class LunchMeCacheFileService extends HttpFileService {
  static const lunchMeImagePath = 'images';

  @override
  Future<FileServiceResponse> get(String url, {Map<String, String>? headers}) async {
    if (isLunchMeFile(url)) {
      var appDirectory = await getApplicationDocumentsDirectory();
      var imageDirectory = join(appDirectory.path, lunchMeImagePath);
      String imageName = getLunchMeFileName(url);
      var imagePath = join(imageDirectory, imageName);
      var imageFile = io.File(imagePath);
      return LunchMeFileServiceResponse(imageFile);
    } else {
      return super.get(url, headers: headers);
    }
  }
}

class LunchMeFileServiceResponse implements FileServiceResponse {
  io.File file;

  LunchMeFileServiceResponse(this.file);

  @override
  Stream<List<int>> get content => file.openRead();

  @override
  int? get contentLength => file.lengthSync();

  @override
  String? get eTag => null;

  @override
  String get fileExtension => extension(file.path);

  @override
  int get statusCode => 200;

  @override
  DateTime get validTill => DateTime(DateTime.now().year + 3);
}
