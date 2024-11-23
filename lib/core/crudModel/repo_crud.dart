// ignore_for_file: avoid_print, use_rethrow_when_possible

import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

import '../models/repo.dart';
import '../services/api.dart';

class CRUDRepo extends ChangeNotifier {
  final Api _api = Api("repository");
  final _storage = FirebaseStorage.instance.ref('repository/');
  late List<Repo> items = [];
  List<Reference> currentFiles = [];
  List<Reference> currentFolders = [];
  String currentPath = "";
  bool isLoading = false;
  String? error;

  Future<List<Repo>> fetchItems() async {
    var result = await _api.getDataCollection();
    items = result.docs
        .map((doc) => Repo.fromFirestore(doc))
        .toList();
    return items;
  }

  Stream<QuerySnapshot> fetchItemsAsStream() {
    return _api.streamDataCollection();
  }

  Future<Repo> getItemsById(String id) async {
    var doc = await _api.getDocumentById(id);
    return Repo.fromFirestore(doc);
  }

  Future removeItem(String id) async {
    await _api.removeDocument(id);
    return;
  }

  Future updateItem(Repo data, String id) async {
    data.validate();
    await _api.updateDocument(data.toMap(), id);
    return;
  }

  Future addItem(Repo data) async {
    data.validate();
    await _api.addDocument(data.toMap());
    return;
  }

  Future<List<Repo>> searchItems(String query) async {
    if (query.isEmpty) return [];
    
    var result = await _api.getDataCollection();
    return result.docs
        .map((doc) => Repo.fromFirestore(doc))
        .where((repo) => 
          repo.name.toLowerCase().contains(query.toLowerCase()) ||
          repo.description.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  Future listFolders(String path) async {
    ListResult result = await _storage.child(path).listAll();
    List<String> folders = [];

    for (var prefix in result.prefixes) {
      folders.add(prefix.name);
    }
    notifyListeners();
    return folders;
  }

  // New method to get collaborators
  Future<List<String>> getCollaborators(String repoId) async {
    try {
      var doc = await _api.getDocumentById(repoId);
      var data = doc.data() as Map<String, dynamic>?;

      if (data != null && data.containsKey('collaborators')) {
        List<dynamic> collaborators = data['collaborators'];
        return collaborators.map((e) => e.toString()).toList();
      } else {
        return [];
      }
    } catch (e) {
      print("Error fetching collaborators: $e");
      return [];
    }
  }

  // New method to schedule deletion
  Future<void> scheduleDeletion(String repoId, DateTime deletionDate) async {
    try {
      await _api.updateDocument(
        {
          'scheduledDeletion': deletionDate.toIso8601String(),
        },
        repoId,
      );
    } catch (e) {
      print("Error scheduling deletion: $e");
    }
  }

  Future<List<Repo>> fetchPaginatedItems(int pageKey, int pageSize,
      {String? searchQuery}) async {
    try {
      // First, let's check what data exists in Firestore
      var allDocs = await _api.ref.get();
      print('Total documents in Firestore: ${allDocs.docs.length}');
      
      for (var doc in allDocs.docs) {
        var data = doc.data() as Map<String, dynamic>;
        print('Doc ID: ${doc.id}, Status: ${data['status']}, Name: ${data['name']}');
      }

      // Changed 'public' to 'Public' to match the case in Firestore
      Query query = _api.ref.where('status', isEqualTo: 'Public');
      
      if (searchQuery != null && searchQuery.isNotEmpty) {
        // Use a compound query for search
        query = query.where('name', isGreaterThanOrEqualTo: searchQuery)
                    .where('name', isLessThanOrEqualTo: '$searchQuery\uf8ff');
      }
      
      // Order by creation date
      query = query.orderBy('createdAt', descending: true);
      
      // Apply pagination
      query = query.limit(pageSize);
      
      // If not the first page, use startAfter with the last document's timestamp
      if (pageKey > 0) {
        // Get all documents up to the current page to find the last document
        var previousDocs = await _api.ref
            .where('status', isEqualTo: 'Public')  // Updated here as well
            .orderBy('createdAt', descending: true)
            .limit(pageKey * pageSize)
            .get();
            
        if (previousDocs.docs.isNotEmpty) {
          var lastDoc = previousDocs.docs.last;
          var lastData = lastDoc.data() as Map<String, dynamic>;
          var lastTimestamp = lastData['createdAt'] as Timestamp;
          
          query = query.startAfter([lastTimestamp]);
        }
      }
      
      var result = await query.get();
      print('Query results: ${result.docs.length} documents found');
      
      for (var doc in result.docs) {
        var data = doc.data() as Map<String, dynamic>;
        print('Found doc with name: ${data['name']}, status: ${data['status']}');
      }
      
      return result.docs.map((doc) => Repo.fromFirestore(doc)).toList();
    } catch (e, stackTrace) {
      print('Error fetching paginated items: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> listFilesAndFolders(String path) async {
    if (isLoading) return;
    
    try {
      isLoading = true;
      error = null;
      notifyListeners();

      final storageRef = FirebaseStorage.instance.ref().child(path);
      final listResult = await storageRef.listAll();

      currentFiles = listResult.items.where((item) => item.name != ".init").toList();
      currentFolders = listResult.prefixes;
      currentPath = path;
    } catch (e) {
      error = 'Error listing files and folders: $e';
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createFolder(String folderName) async {
    try {
      isLoading = true;
      error = null;
      notifyListeners();

      final newFolderRef = _storage.child('$currentPath/$folderName');
      await newFolderRef.child('.init').putData(Uint8List(0));
      
      await listFilesAndFolders(currentPath);
    } catch (e) {
      error = 'Error creating folder: $e';
      isLoading = false;
      notifyListeners();
      throw e;
    }
  }

  Future<void> deleteFolder(Reference folder) async {
    try {
      isLoading = true;
      error = null;
      notifyListeners();

      final listResult = await folder.listAll();

      // Delete all files in the folder
      await Future.wait(listResult.items.map((item) => item.delete()));

      // Recursively delete all subfolders
      await Future.wait(
        listResult.prefixes.map((prefix) => deleteFolder(prefix)),
      );

      await listFilesAndFolders(currentPath);
    } catch (e) {
      error = 'Error deleting folder: $e';
      isLoading = false;
      notifyListeners();
      throw e;
    }
  }

  Future<void> renameFolder(Reference folder, String newName) async {
    try {
      isLoading = true;
      error = null;
      notifyListeners();

      final listResult = await folder.listAll();
      final parentPath = currentPath;
      final newFolderRef = _storage.child('$parentPath/$newName');

      // Copy all files to new location
      for (var item in listResult.items) {
        final fileName = item.name;
        final newItemRef = newFolderRef.child(fileName);
        
        final data = await item.getData();
        if (data != null) {
          await newItemRef.putData(data);
          await item.delete();
        }
      }

      // Handle subfolders recursively
      for (var prefix in listResult.prefixes) {
        final subfolderName = prefix.name;
        final newSubfolderRef = newFolderRef.child(subfolderName);
        await _copyFolder(prefix, newSubfolderRef);
        await deleteFolder(prefix);
      }

      await listFilesAndFolders(currentPath);
    } catch (e) {
      error = 'Error renaming folder: $e';
      isLoading = false;
      notifyListeners();
      throw e;
    }
  }

  Future<void> _copyFolder(Reference sourceFolder, Reference targetFolder) async {
    final listResult = await sourceFolder.listAll();

    // Copy all files
    for (var item in listResult.items) {
      final data = await item.getData();
      if (data != null) {
        await targetFolder.child(item.name).putData(data);
      }
    }

    // Recursively copy subfolders
    for (var prefix in listResult.prefixes) {
      final newSubfolderRef = targetFolder.child(prefix.name);
      await _copyFolder(prefix, newSubfolderRef);
    }
  }

  Future<void> uploadFile(String fileName, Uint8List fileData) async {
    try {
      isLoading = true;
      error = null;
      notifyListeners();

      final fileRef = _storage.child('$currentPath/$fileName');
      await fileRef.putData(fileData);
      
      await listFilesAndFolders(currentPath);
    } catch (e) {
      error = 'Error uploading file: $e';
      isLoading = false;
      notifyListeners();
      throw e;
    }
  }

  Future<void> deleteFile(Reference file) async {
    try {
      isLoading = true;
      error = null;
      notifyListeners();

      await file.delete();
      await listFilesAndFolders(currentPath);
    } catch (e) {
      error = 'Error deleting file: $e';
      isLoading = false;
      notifyListeners();
      throw e;
    }
  }

  Future<void> renameFile(Reference file, String newName) async {
    try {
      isLoading = true;
      error = null;
      notifyListeners();

      final data = await file.getData();
      if (data != null) {
        final newFileRef = _storage.child('$currentPath/$newName');
        await newFileRef.putData(data);
        await file.delete();
      }

      await listFilesAndFolders(currentPath);
    } catch (e) {
      error = 'Error renaming file: $e';
      isLoading = false;
      notifyListeners();
      throw e;
    }
  }

  Future<String> getDownloadUrl(Reference file) async {
    try {
      return await file.getDownloadURL();
    } catch (e) {
      error = 'Error getting download URL: $e';
      notifyListeners();
      throw e;
    }
  }
}
