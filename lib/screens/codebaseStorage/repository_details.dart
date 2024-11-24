// ignore_for_file: avoid_print, prefer_const_constructors, library_private_types_in_public_api, depend_on_referenced_packages, avoid_types_as_parameter_names, sized_box_for_whitespace

import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/crudModel/repo_crud.dart';
import '../../core/crudModel/user_crud.dart';
import '../../core/models/repo.dart';
import '../../core/models/user.dart';
import '../../widgets/detail_header.dart';
import '../../widgets/stats_section.dart';
import '../../widgets/user_section.dart';

class Folder {
  String name;
  String path;
  Folder(this.name, this.path) {
    name = name;
    path = path;
  }
}

class OurOwnFile {
  final String name;
  final FullMetadata data;

  OurOwnFile(this.name, this.data);
}

class RepositoryDetailPage extends StatefulWidget {
  final Repo repository;

  const RepositoryDetailPage({super.key, required this.repository});

  @override
  State<RepositoryDetailPage> createState() => _RepositoryDetailPageState();
}

class _RepositoryDetailPageState extends State<RepositoryDetailPage> {
  String currentPath = "";
  bool rootFolder = true;
  double setsize = 0;
  List<Folder> folders = [];
  List<OurOwnFile> files = [];
  int fullSize = 0;
  bool isLoading = false;
  String? error;
  Future<List<User>>? _itemsFuture;
  Map<String, User> userCache = {};
  Map<String, User> userIdCache = {};

  @override
  void initState() {
    var userProvider = Provider.of<CRUDUser>(context, listen: false);
    _itemsFuture = userProvider.fetchItems();
    _fetchUsers();
    listFilesInFolder("repository/${widget.repository.name}", true);
    super.initState();
  }

  Future<void> _fetchUsers() async {
    List<User> users = await _itemsFuture ?? [];
    for (var user in users) {
      if (user.studentId != null) {
        userCache[user.studentId!] = user;
      }
      userIdCache[user.id] = user;
    }
    setState(() {});
  }

  User getUserByStudentID(String id) {
    var user = userCache[id];
    if (user != null) {
      return user;
    } else {
      return User.empty();
    }
  }

  User getUserById(String id) {
    var user = userIdCache[id];
    if (user != null) {
      return user;
    } else {
      return User.empty();
    }
  }

  List<String> getBreadcrumbItems() {
    if (currentPath.isEmpty) return [];
    List<String> parts = currentPath.split('/');
    return parts.sublist(1); // Remove 'repository' from the path
  }

  Future<void> navigateToPath(String path) async {
    if (path == currentPath) return; // Don't navigate if we're already here

    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      await listFilesInFolder(path, path.split("/").length <= 2);
    } catch (e) {
      setState(() {
        error = 'Error navigating to folder: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> listFilesInFolder(String path, bool root) async {
    List<OurOwnFile> newFiles = [];
    List<Folder> newFolders = [];

    final storageRef = FirebaseStorage.instance.ref().child(path);

    try {
      final listResult = await storageRef.listAll();

      // Get all files first
      await Future.wait(
        listResult.items
            .where((item) => item.name != ".init")
            .map((item) async {
          final metadata = await item.getMetadata();
          newFiles.add(OurOwnFile(item.name, metadata));
        }),
      );

      // Then get all folders
      for (final prefix in listResult.prefixes) {
        newFolders.add(Folder(prefix.name, prefix.fullPath));
      }

      setState(() {
        files = newFiles;
        folders = newFolders;
        rootFolder = root;
        currentPath = path;
        getFullSize();
      });
    } catch (e) {
      throw Exception('Error listing files: $e');
    }
  }

  Future<void> goBackOneFolder() async {
    List<String> currentPathFolders = currentPath.split("/");
    String newPath =
        currentPathFolders.sublist(0, currentPathFolders.length - 1).join("/");
    await navigateToPath(newPath);
  }

  getFullSize() {
    int total = 0;
    for (OurOwnFile file in files) {
      total = total + file.data.size!;
    }
    fullSize = total;
    // setState(() {});
  }

  Future<void> createFolder(String folderName) async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      final storage = FirebaseStorage.instance.ref(currentPath);
      final newFolderRef = storage.child(folderName);

      // Create .init file to make the folder exist
      await newFolderRef.child('.init').putData(Uint8List(0));

      // Refresh the current directory to show the new folder
      await listFilesInFolder(currentPath, rootFolder);
    } catch (e) {
      setState(() {
        error = 'Error creating folder: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> deleteFolder(Folder folder, bool isNested) async {
    try {
      if (!isNested) {
        setState(() {
          isLoading = true;
          error = null;
        });
      }

      final storageRef = FirebaseStorage.instance.ref().child(folder.path);
      final listResult = await storageRef.listAll();

      // Delete all files in the folder
      await Future.wait(
        listResult.items.map((item) => item.delete()),
      );

      // Recursively delete all subfolders
      await Future.wait(
        listResult.prefixes.map(
          (prefix) => deleteFolder(Folder(prefix.name, prefix.fullPath), true),
        ),
      );

      if (!isNested) {
        // Refresh the current directory after deletion
        await listFilesInFolder(currentPath, rootFolder);
      }
    } catch (e) {
      if (!isNested) {
        setState(() {
          error = 'Error deleting folder: $e';
        });
      }
      print('Error deleting folder: $e');
    } finally {
      if (!isNested) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> renameFolder(Folder folder, String newName) async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      // Get reference to old and new paths
      final oldFolderRef = FirebaseStorage.instance.ref().child(folder.path);
      final parentPath = path.dirname(folder.path);
      final newPath = "$parentPath/$newName";
      final newFolderRef = FirebaseStorage.instance.ref().child(newPath);

      // List all items in the old folder
      final listResult = await oldFolderRef.listAll();

      // Copy all files to new location
      for (var item in listResult.items) {
        final fileName = path.basename(item.fullPath);
        final newItemRef = newFolderRef.child(fileName);

        // Download and upload the file
        final data = await item.getData();
        if (data != null) {
          await newItemRef.putData(data);
          await item.delete();
        }
      }

      // Handle subfolders recursively
      for (var prefix in listResult.prefixes) {
        final subfolderName = path.basename(prefix.fullPath);
        await renameFolder(
          Folder(subfolderName, prefix.fullPath),
          subfolderName, // Keep same name for subfolders
        );
      }

      // Create .init file in the new folder
      await newFolderRef.child('.init').putData(Uint8List(0));

      // Refresh current directory
      await listFilesInFolder(currentPath, rootFolder);
    } catch (e) {
      setState(() {
        error = 'Error renaming folder: $e';
      });
      print('Error renaming folder: $e'); // For debugging
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _showFolderOptionsDialog(Folder folder) {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Folder Options'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                leading: Icon(Icons.drive_file_rename_outline),
                title: Text('Rename'),
                onTap: () {
                  Navigator.pop(context);
                  _showRenameDialog(folder);
                },
              ),
              ListTile(
                leading: Icon(Icons.delete_outline, color: Colors.red),
                title: Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmationDialog(folder);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showRenameDialog(Folder folder) async {
    final TextEditingController nameController =
        TextEditingController(text: folder.name);

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Rename Folder'),
          content: TextField(
            controller: nameController,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Folder Name',
              hintText: 'Enter new folder name',
            ),
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: Text('Rename'),
              onPressed: () {
                if (nameController.text.isNotEmpty &&
                    nameController.text != folder.name) {
                  Navigator.pop(context);
                  renameFolder(folder, nameController.text);
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showDeleteConfirmationDialog(Folder folder) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Folder'),
          content: Text(
            'Are you sure you want to delete "${folder.name}"?\nThis action cannot be undone.',
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () {
                Navigator.pop(context);
                deleteFolder(folder, false);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> uploadFile() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      FilePickerResult? result = await FilePicker.platform.pickFiles();
      if (result == null) {
        setState(() {
          isLoading = false;
        });
        return;
      }

      File file = File(result.files.single.path!);
      String fileName = path.basename(file.path);
      String filePath = '$currentPath/$fileName';

      final storageRef = FirebaseStorage.instance.ref().child(filePath);
      await storageRef.putFile(file);

      await listFilesInFolder(currentPath, rootFolder);
    } catch (e) {
      setState(() {
        error = 'Error uploading file: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> downloadFile(OurOwnFile file) async {
    try {
      final storageRef = FirebaseStorage.instance.ref().child('$currentPath/${file.name}');
      final url = await storageRef.getDownloadURL();
      await launchUrl(Uri.parse(url));
    } catch (e) {
      setState(() {
        error = 'Error downloading file: $e';
      });
    }
  }

  Future<void> deleteFile(OurOwnFile file) async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      final storageRef = FirebaseStorage.instance.ref().child('$currentPath/${file.name}');
      await storageRef.delete();

      await listFilesInFolder(currentPath, rootFolder);
    } catch (e) {
      setState(() {
        error = 'Error deleting file: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  double calculateWidth(double percentage) {
    return setsize * (percentage / 100);
  }

  @override
  Widget build(BuildContext context) {
    Provider.of<CRUDRepo>(context);
    Provider.of<CRUDUser>(context);
    setsize = MediaQuery.of(context).size.width - 50;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.repository.name),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: Column(
        children: [
          DetailHeader(
            title: widget.repository.name,
            description: widget.repository.description,
            createdAt: widget.repository.createdAt,
            languages: widget.repository.languages,
            categories: widget.repository.categories,
            status: widget.repository.status,
            padding: EdgeInsets.symmetric(horizontal: 25.w, vertical: 15.h),
          ),
          StatsSection(
            stats: [
              StatItem(
                label: 'Files',
                value: widget.repository.files.length.toString(),
                icon: Icons.insert_drive_file,
              ),
              StatItem(
                label: 'Size',
                value: '${(fullSize / 1024).toStringAsFixed(2)} KB',
                icon: Icons.data_usage,
              ),
            ],
          ),
          UserSection(
            owner: getUserById(widget.repository.userId),
            collaborators: widget.repository.collabs.map((id) => getUserById(id)).toList(),
          ),
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                if (!rootFolder)
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: goBackOneFolder,
                  ),
                Expanded(
                  child: Text(
                    currentPath.isEmpty ? 'Root' : getBreadcrumbItems().join(' / '),
                    style: TextStyle(fontSize: 16.sp),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.create_new_folder),
                  onPressed: () async {
                    final TextEditingController controller = TextEditingController();
                    await showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Create New Folder'),
                        content: TextField(
                          controller: controller,
                          decoration: const InputDecoration(hintText: 'Folder Name'),
                        ),
                        actions: [
                          TextButton(
                            child: const Text('Cancel'),
                            onPressed: () => Navigator.pop(context),
                          ),
                          TextButton(
                            child: const Text('Create'),
                            onPressed: () {
                              if (controller.text.isNotEmpty) {
                                createFolder(controller.text);
                              }
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.upload_file),
                  onPressed: uploadFile,
                ),
              ],
            ),
          ),
          if (error != null)
            Padding(
              padding: EdgeInsets.all(8.w),
              child: Text(
                error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          if (isLoading)
            const Center(child: CircularProgressIndicator())
          else
            Expanded(
              child: ListView(
                children: [
                  ...folders.map((folder) => ListTile(
                    leading: const Icon(Icons.folder),
                    title: Text(folder.name),
                    onTap: () => navigateToPath(folder.path),
                  )),
                  ...files.map((file) => ListTile(
                    leading: const Icon(Icons.insert_drive_file),
                    title: Text(file.name),
                    subtitle: Text('Size: ${(file.data.size! / 1024).toStringAsFixed(2)} KB'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.download),
                          onPressed: () => downloadFile(file),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => deleteFile(file),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
