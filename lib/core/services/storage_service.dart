import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:path/path.dart' as path_util;

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadProfilePicture(String userId, dynamic imageData) async {
    try {
      final String fileName =
          'profile_${userId}_${DateTime.now().millisecondsSinceEpoch}';
      final Reference ref = _storage.ref().child('profile_pictures/$fileName');

      UploadTask uploadTask;
      if (imageData is File) {
        uploadTask = ref.putFile(imageData);
      } else if (imageData is Uint8List) {
        uploadTask = ref.putData(imageData);
      } else {
        throw Exception('Unsupported image data type');
      }

      final TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload profile picture: $e');
    }
  }

  Future<String> uploadFile(String path, File file) async {
    try {
      final String extension = path_util.extension(file.path);
      final String fileName =
          '${DateTime.now().millisecondsSinceEpoch}$extension';
      final Reference ref = _storage.ref().child('$path/$fileName');

      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload file: $e');
    }
  }

  Future<List<String>> uploadFiles(String path, List<File> files) async {
    List<String> urls = [];
    for (var file in files) {
      String url = await uploadFile(path, file);
      urls.add(url);
    }
    return urls;
  }

  Future<void> deleteFile(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (e) {
      throw Exception('Failed to delete file: $e');
    }
  }
}
