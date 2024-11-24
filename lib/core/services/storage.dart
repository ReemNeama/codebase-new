import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as p;

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Upload file
  Future<String> uploadFile(String path, File file) async {
    try {
      final ref = _storage.ref().child(path);
      final uploadTask = await ref.putFile(file);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      throw 'Failed to upload file: ${e.toString()}';
    }
  }

  // Upload data
  Future<String> uploadData(String path, Uint8List data,
      {String? contentType}) async {
    try {
      final ref = _storage.ref().child(path);
      final metadata = contentType != null
          ? SettableMetadata(contentType: contentType)
          : null;
      final uploadTask = await ref.putData(data, metadata);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      throw 'Failed to upload data: ${e.toString()}';
    }
  }

  // Get file extension
  String getFileExtension(String path) {
    return p.extension(path).toLowerCase();
  }

  // Delete file
  Future<void> deleteFile(String path) async {
    try {
      final ref = _storage.ref().child(path);
      await ref.delete();
    } catch (e) {
      throw 'Failed to delete file: ${e.toString()}';
    }
  }

  // List files in directory
  Future<ListResult> listFiles(String path) async {
    try {
      final ref = _storage.ref().child(path);
      return await ref.listAll();
    } catch (e) {
      throw 'Failed to list files: ${e.toString()}';
    }
  }

  // Get download URL
  Future<String> getDownloadURL(String path) async {
    try {
      final ref = _storage.ref().child(path);
      return await ref.getDownloadURL();
    } catch (e) {
      throw 'Failed to get download URL: ${e.toString()}';
    }
  }

  // Copy file
  Future<void> copyFile(String sourcePath, String destinationPath) async {
    try {
      final sourceRef = _storage.ref().child(sourcePath);
      final destinationRef = _storage.ref().child(destinationPath);

      final data = await sourceRef.getData();
      if (data != null) {
        await destinationRef.putData(data);
      }
    } catch (e) {
      throw 'Failed to copy file: ${e.toString()}';
    }
  }

  // Move file
  Future<void> moveFile(String sourcePath, String destinationPath) async {
    try {
      await copyFile(sourcePath, destinationPath);
      await deleteFile(sourcePath);
    } catch (e) {
      throw 'Failed to move file: ${e.toString()}';
    }
  }

  uploadProfilePicture(String id, imageData) {}
}
