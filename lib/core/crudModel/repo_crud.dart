// ignore_for_file: avoid_print, use_rethrow_when_possible

import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../base/base_crud.dart';
import '../models/repo.dart';
import '../services/api.dart';

class CRUDRepo extends BaseCRUD<Repo> {
  final Api _api = Api("repository");
  final _storage = FirebaseStorage.instance.ref('repository/');
  List<Reference> currentFiles = [];
  List<Reference> currentFolders = [];
  String currentPath = "";

  CRUDRepo() : super("repository");

  @override
  Map<String, dynamic> toJson(Repo item) => item.toMap();

  @override
  Repo fromJson(Map<String, dynamic>? data, String id) =>
      Repo.fromMap(data, id);

  Stream<QuerySnapshot> fetchItemsAsStream() {
    return _api.streamDataCollection();
  }

  Future<Repo> getItemsById(String id) async {
    var doc = await _api.getDocumentById(id);
    return Repo.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  @override
  Future<List<Repo>> fetchPaginatedItems({
    required int pageSize,
    DocumentSnapshot? lastDocument,
    String? orderBy,
  }) async {
    try {
      var query = _api.ref.orderBy(orderBy ?? 'name').limit(pageSize);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      var snapshot = await query.get();
      return snapshot.docs
          .map((doc) => fromJson(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e, stackTrace) {
      print('Error fetching paginated items: $e');
      print('Stack trace: $stackTrace');
      return [];
    }
  }

  List<Repo> searchRepos(String query) {
    if (query.isEmpty) return items;
    return items
        .where((repo) =>
            repo.name.toLowerCase().contains(query.toLowerCase()) ||
            repo.description.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  Future<List<String>> listFolders(String path) async {
    ListResult result = await _storage.child(path).listAll();
    List<String> folders = [];

    for (var prefix in result.prefixes) {
      folders.add(prefix.name);
    }
    notifyListeners();
    return folders;
  }

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

  Future<void> listFilesAndFolders(String path) async {
    if (isLoading) return;

    try {
      isLoading = true;
      error = null;
      notifyListeners();

      ListResult result = await _storage.child(path).listAll();

      currentFiles = result.items;
      currentFolders = result.prefixes;
      currentPath = path;
    } catch (e) {
      error = e.toString();
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

  Future<void> _copyFolder(
      Reference sourceFolder, Reference targetFolder) async {
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
