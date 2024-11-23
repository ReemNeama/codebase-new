// ignore_for_file: avoid_print, prefer_const_constructors, library_private_types_in_public_api, depend_on_referenced_packages, avoid_types_as_parameter_names, sized_box_for_whitespace

import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/crudModel/repo_crud.dart';
import '../../core/crudModel/user_crud.dart';
import '../../core/models/repo.dart';
import '../../core/models/user.dart';

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
        listResult.items.where((item) => item.name != ".init").map((item) async {
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
    String newPath = currentPathFolders.sublist(0, currentPathFolders.length - 1).join("/");
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

  Future<void> _showFolderOptionsDialog(Folder folder) async {
    
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
    final TextEditingController nameController = TextEditingController(text: folder.name);
    
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
                if (nameController.text.isNotEmpty && nameController.text != folder.name) {
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

  Future<void> uploadFile(String folderPath) async {
    final pickedFile =
        await FilePicker.platform.pickFiles(allowMultiple: false);
    if (pickedFile != null) {
      final file = File(pickedFile.files.single.path!);
      final fileName = path.basename(file.path);
      final storageRef = FirebaseStorage.instance.ref('$folderPath/$fileName');

      try {
        final uploadTask = storageRef.putFile(file);

        // Handle upload progress (optional)
        uploadTask.snapshotEvents.listen((snapshot) {
          final progress =
              (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
          print('Upload is ${progress.toStringAsFixed(0)}% complete.');
        });

        // Handle upload completion and metadata update
        final snapshot = await uploadTask;
        final downloadUrl = await snapshot.ref.getDownloadURL();
        final metadata =
            SettableMetadata(customMetadata: {'status': 'uploaded'});
        await snapshot.ref.updateMetadata(metadata);

        // Create a new OurOwnFile object with metadata
        final newFile = OurOwnFile(
            pickedFile.files.single.name, await snapshot.ref.getMetadata());

        // Add the new file to the files list and update UI
        setState(() {
          files.add(newFile);
          fullSize += newFile.data.size!;
          getFullSize();
        });

        print('File uploaded successfully: $downloadUrl');
      } on FirebaseException catch (e) {
        print('Error uploading file: $e');
      }
    } else {
      print('No file selected.');
    }
  }

  String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1048576) {
      return '${bytes / 1024} KB';
    } else {
      return "0";
    }
  }

  Future<void> downloadFile(OurOwnFile file) async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      final fileRef = FirebaseStorage.instance.ref().child("$currentPath/${file.name}");
      final url = await fileRef.getDownloadURL();
      
      // Launch URL in browser for download
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        throw 'Could not launch download URL';
      }
    } catch (e) {
      setState(() {
        error = 'Error downloading file: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> deleteFile(OurOwnFile file) async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      final fileRef = FirebaseStorage.instance.ref().child("$currentPath/${file.name}");
      await fileRef.delete();
      
      // Refresh the current directory
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

  Future<void> renameFile(OurOwnFile file, String newName) async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      final oldFileRef = FirebaseStorage.instance.ref().child("$currentPath/${file.name}");
      final newFileRef = FirebaseStorage.instance.ref().child("$currentPath/$newName");

      // Download old file data
      final data = await oldFileRef.getData();
      if (data != null) {
        // Upload to new location
        await newFileRef.putData(
          data,
          SettableMetadata(
            contentType: file.data.contentType,
            customMetadata: file.data.customMetadata,
          ),
        );
        // Delete old file
        await oldFileRef.delete();
      }

      // Refresh the current directory
      await listFilesInFolder(currentPath, rootFolder);
    } catch (e) {
      setState(() {
        error = 'Error renaming file: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _showFileOptionsDialog(OurOwnFile file) {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('File Options'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                leading: Icon(Icons.download),
                title: Text('Download'),
                onTap: () {
                  Navigator.pop(context);
                  downloadFile(file);
                },
              ),
              ListTile(
                leading: Icon(Icons.drive_file_rename_outline),
                title: Text('Rename'),
                onTap: () {
                  Navigator.pop(context);
                  _showFileRenameDialog(file);
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
                  _showFileDeleteConfirmationDialog(file);
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

  Future<void> _showFileRenameDialog(OurOwnFile file) {
    final TextEditingController nameController = TextEditingController(text: file.name);
    final extension = path.extension(file.name);
    final baseName = path.basenameWithoutExtension(file.name);
    nameController.text = baseName;
    nameController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: baseName.length,
    );

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Rename File'),
          content: TextField(
            controller: nameController,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'File Name',
              hintText: 'Enter new file name',
              suffixText: extension,
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
                final newName = nameController.text + extension;
                if (newName.isNotEmpty && newName != file.name) {
                  Navigator.pop(context);
                  renameFile(file, newName);
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showFileDeleteConfirmationDialog(OurOwnFile file) {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete File'),
          content: Text(
            'Are you sure you want to delete "${file.name}"?\nThis action cannot be undone.',
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
                deleteFile(file);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildFolderList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Back button and current path
        if (!rootFolder) Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.r),
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back, size: 20),
                onPressed: goBackOneFolder,
                tooltip: 'Go back',
                padding: EdgeInsets.all(8.r),
                constraints: BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      TextButton.icon(
                        icon: Icon(Icons.home, size: 16),
                        label: Text('Root', style: TextStyle(fontSize: 12.sp)),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(horizontal: 8.r),
                        ),
                        onPressed: () {
                          navigateToPath("repository/${widget.repository.name}");
                        },
                      ),
                      ...getBreadcrumbItems().asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.chevron_right, size: 16),
                            TextButton(
                              onPressed: () {
                                String path = "repository/${getBreadcrumbItems().sublist(0, index + 1).join('/')}";
                                navigateToPath(path);
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.symmetric(horizontal: 8.r),
                              ),
                              child: Text(
                                item,
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: index == getBreadcrumbItems().length - 1 
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Folders grid
        if (folders.isNotEmpty) Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.r, vertical: 8.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Folders',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8.h),
              GridView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: MediaQuery.of(context).size.width ~/ 100, // Smaller tiles
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 0.85, // Slightly taller than wide for the name
                ),
                itemCount: folders.length,
                itemBuilder: (context, index) {
                  final folder = folders[index];
                  return InkWell(
                    onTap: () => navigateToPath(folder.path),
                    borderRadius: BorderRadius.circular(6.r),
                    child: Container(
                      padding: EdgeInsets.all(4.r),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
                          width: 0.5,
                        ),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Icon(
                                Icons.folder,
                                size: 32,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              Positioned(
                                top: -8,
                                right: -8,
                                child: IconButton(
                                  icon: Icon(Icons.more_vert, size: 16),
                                  padding: EdgeInsets.zero,
                                  constraints: BoxConstraints(
                                    minWidth: 16,
                                    minHeight: 16,
                                  ),
                                  onPressed: () => _showFolderOptionsDialog(folder),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            folder.name,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 11.sp),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        
        // Files list
        if (files.isNotEmpty) Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.r, vertical: 8.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Files',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8.h),
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: files.length,
                itemBuilder: (context, index) {
                  final file = files[index];
                  return ListTile(
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    leading: Icon(
                      _getFileIcon(file.name),
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: Text(
                      file.name,
                      style: TextStyle(fontSize: 12.sp),
                    ),
                    subtitle: Text(
                      formatFileSize(file.data.size ?? 0),
                      style: TextStyle(fontSize: 10.sp),
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.more_vert, size: 18),
                      onPressed: () => _showFileOptionsDialog(file),
                      constraints: BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        
        if (folders.isEmpty && files.isEmpty) Center(
          child: Padding(
            padding: EdgeInsets.all(24.r),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.folder_open,
                  size: 48,
                  color: Theme.of(context).colorScheme.outline,
                ),
                SizedBox(height: 8.h),
                Text(
                  'This folder is empty',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  IconData _getFileIcon(String fileName) {
    final extension = path.extension(fileName).toLowerCase();
    switch (extension) {
      case '.pdf':
        return Icons.picture_as_pdf;
      case '.jpg':
      case '.jpeg':
      case '.png':
      case '.gif':
        return Icons.image;
      case '.doc':
      case '.docx':
        return Icons.description;
      case '.xls':
      case '.xlsx':
        return Icons.table_chart;
      case '.txt':
        return Icons.article;
      default:
        return Icons.insert_drive_file;
    }
  }

  @override
  Widget build(BuildContext context) {
    Provider.of<CRUDRepo>(context);
    Provider.of<CRUDUser>(context);
    setsize = MediaQuery.of(context).size.width - 50;

    // double totalSizeKB = 20.0;
// Calculate the size distribution for each type
    double codeSize = calculateWidth(files, "code");
    double documentsSize = calculateWidth(files, "documents");
    double imagesSize = calculateWidth(files, "images");
    double otherFilesSize = setsize - (codeSize + documentsSize + imagesSize);

    // Calculate percentages
    double codePercentage = (codeSize / setsize * 100).clamp(0, 100);
    double documentsPercentage = (documentsSize / setsize * 100).clamp(0, 100);
    double imagesPercentage = (imagesSize / setsize * 100).clamp(0, 100);
    double otherFilesPercentage =
        (otherFilesSize / setsize * 100).clamp(0, 100);

    // Calculate widths based on percentages
    double codeWidth = setsize * (codePercentage / 100);
    double documentsWidth = setsize * (documentsPercentage / 100);
    double imagesWidth = setsize * (imagesPercentage / 100);
    double otherFilesWidth = setsize * (otherFilesPercentage / 100);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: Text(widget.repository.name),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 25.w, vertical: 15.h),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20.r),
                  bottomRight: Radius.circular(20.r),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Created on ${DateFormat('MMM d, y').format(widget.repository.createdAt)}',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    widget.repository.description,
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  if (widget.repository.languages.isNotEmpty) ...[
                    Text(
                      'Languages',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children: widget.repository.languages
                          .map((lang) => Chip(
                                label: Text(lang),
                                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                labelStyle: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer),
                              ))
                          .toList(),
                    ),
                    SizedBox(height: 16.h),
                  ],
                  if (widget.repository.categories.isNotEmpty) ...[
                    Text(
                      'Categories',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children: widget.repository.categories
                          .map((category) => Chip(
                                label: Text(category),
                                backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                                labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSecondaryContainer),
                              ))
                          .toList(),
                    ),
                    SizedBox(height: 16.h),
                  ],
                  Row(
                    children: [
                      Icon(
                        Icons.public,
                        color: Theme.of(context).colorScheme.onPrimary,
                        size: 20.sp,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        widget.repository.status,
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ],
                  ),
                  if (widget.repository.url != null) ...[
                    SizedBox(height: 16.h),
                    InkWell(
                      onTap: () async {
                        final Uri url = Uri.parse(widget.repository.url!);
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url);
                        }
                      },
                      child: Row(
                        children: [
                          Icon(
                            Icons.link,
                            color: Theme.of(context).colorScheme.onPrimary,
                            size: 20.sp,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            widget.repository.url ?? "Not available",
                            style: TextStyle(
                              fontSize: 16.sp,
                              color: Theme.of(context).colorScheme.onPrimary,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 25.w, vertical: 20.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    elevation: 2,
                    margin: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(16.r),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Developers',
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 12.h),
                          Builder(
                            builder: (context) {
                              final creator = getUserById(widget.repository.userId);
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: CircleAvatar(
                                  backgroundColor: Theme.of(context).colorScheme.primary,
                                  child: Text(
                                    (creator.firstName.isNotEmpty ? creator.firstName[0] : '?') +
                                        (creator.lastName.isNotEmpty ? creator.lastName[0] : ''),
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onPrimary,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  '${creator.firstName} ${creator.lastName}',
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                subtitle: Text(
                                  'Creator',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            },
                          ),
                          ...widget.repository.collabs.map((collab) {
                            final user = getUserByStudentID(collab);
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                child: Text(
                                  (user.firstName.isNotEmpty ? user.firstName[0] : '?') +
                                      (user.lastName.isNotEmpty ? user.lastName[0] : ''),
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onPrimary,
                                  ),
                                ),
                              ),
                              title: Text(
                                '${user.firstName} ${user.lastName}',
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              subtitle: Text(
                                'Developer',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 24.h),
                  Card(
                    elevation: 2,
                    margin: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(16.r),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Storage',
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '$fullSize/20KB',
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16.h),
                          ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: setsize > 0 ? setsize : 0),
                            child: Column(
                              children: [
                                if (codeWidth > 0) _buildStorageBar(
                                  'Code',
                                  codePercentage,
                                  Colors.blue,
                                ),
                                if (documentsWidth > 0) _buildStorageBar(
                                  'Documents',
                                  documentsPercentage,
                                  Colors.green,
                                ),
                                if (imagesWidth > 0) _buildStorageBar(
                                  'Images',
                                  imagesPercentage,
                                  Colors.orange,
                                ),
                                if (otherFilesWidth > 0) _buildStorageBar(
                                  'Others',
                                  otherFilesPercentage,
                                  Colors.grey,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 24.h),
                  Card(
                    elevation: 2,
                    margin: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.all(16.r),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Project Files',
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.create_new_folder),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) => FolderPop(
                                          onEnterPressed: (folderName) {
                                            createFolder(folderName);
                                          },
                                        ),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.upload_file),
                                    onPressed: () {
                                      uploadFile(currentPath);
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        _buildFolderList(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStorageBar(String label, double percentage, Color color) {
    return Row(
      children: [
        SizedBox(
          width: 80.w, // Fixed width for label
          child: Text(
            label,
            style: TextStyle(fontSize: 14.sp),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: color.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        SizedBox(width: 8.w),
        SizedBox(
          width: 45.w, // Fixed width for percentage
          child: Text(
            '${percentage.toStringAsFixed(1)}%',
            style: TextStyle(fontSize: 14.sp),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  double calculateWidth(List<OurOwnFile> files, String type) {
    // Ensure total size does not exceed 20KB
    int totalSize = fullSize.clamp(0, 20480); // 20480 bytes = 20KB

    if (totalSize == 0) {
      return 0.0;
    }

    // Filter files based on type and sum their sizes
    int typeSize = files
        .where((file) =>
            (type == "code" &&
                (file.name.endsWith(".cpp") ||
                    file.name.endsWith(".h") ||
                    file.name.endsWith(".c") ||
                    file.name.endsWith(".py") ||
                    file.name.endsWith(".js") ||
                    file.name.endsWith(".java") ||
                    file.name.endsWith(".swift"))) ||
            (type == "documents" &&
                (file.name.endsWith(".doc") ||
                    file.name.endsWith(".docx") ||
                    file.name.endsWith(".pdf") ||
                    file.name.endsWith(".txt") ||
                    file.name.endsWith(".xls") ||
                    file.name.endsWith(".xlsx"))) ||
            (type == "images" &&
                (file.name.endsWith(".jpg") ||
                    file.name.endsWith(".jpeg") ||
                    file.name.endsWith(".png") ||
                    file.name.endsWith(".gif"))))
        .fold(0, (sum, file) => sum + file.data.size!);

    // Calculate ratio of specific type size to total size
    double ratio = typeSize / totalSize;
    return setsize * ratio; // Multiply ratio by available width
  }
}

class FolderPop extends StatefulWidget {
  final Function(String) onEnterPressed;

  const FolderPop({super.key, required this.onEnterPressed});

  @override
  _FolderPopState createState() => _FolderPopState();
}

class _FolderPopState extends State<FolderPop> {
  final TextEditingController _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Folder'),
      content: TextField(
        controller: _textController,
        onSubmitted: (value) {
          widget.onEnterPressed(value);
          Navigator.of(context).pop(); // Close the popup
        },
        decoration: const InputDecoration(
          hintText: 'FolderName',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // Close the popup
          },
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            widget.onEnterPressed(_textController.text);
            Navigator.of(context).pop(); // Close the popup
          },
          child: const Text('OK'),
        ),
      ],
    );
  }
}