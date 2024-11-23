import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
// ignore: depend_on_referenced_packages
import 'package:path/path.dart' as path;

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadProfilePicture(String userId, File imageFile) async {
    try {
      // Create a unique file name using the user ID and timestamp
      String fileName = 'profile_${userId}_${DateTime.now().millisecondsSinceEpoch}${path.extension(imageFile.path)}';
      
      // Create a reference to the file location
      Reference ref = _storage.ref().child('profile_pictures/$fileName');
      
      // Upload the file
      await ref.putFile(imageFile);
      
      // Get the download URL
      String downloadURL = await ref.getDownloadURL();
      
      return downloadURL;
    } catch (e) {
      throw Exception('Failed to upload profile picture: $e');
    }
  }
}
