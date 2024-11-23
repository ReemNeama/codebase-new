// ignore_for_file: constant_identifier_names, use_build_context_synchronously, prefer_const_constructors, avoid_print

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/crudModel/project_crud.dart';
import '../../core/models/project.dart';

final FirebaseStorage storage = FirebaseStorage.instanceFor(
  bucket: "utbcodebase.appspot.com",
);

class AddApp extends StatefulWidget {
  const AddApp({super.key});

  @override
  State<AddApp> createState() => _AddAppState();
}

enum GraduationProjectType { Yes, No }

class _AddAppState extends State<AddApp> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  GraduationProjectType _selectedProject = GraduationProjectType.No;

  XFile? _logo;
  XFile? _apkFile;
  XFile? _ipaFile;
  List<XFile> _screenshots = [];

  final ImagePicker _picker = ImagePicker();

  final List<String> _categories = [
    'Restaurant and Food Delivery',
    'Educational',
    'Lifestyle',
    'Social Media',
    'Game',
    'Productivity',
    'Business',
    'Healthcare',
    'Pet Care',
    'Grocery Delivery',
    'Finance',
    'Travel',
    'Cooking',
    'Fitness',
    'Entertainment',
    'Photo and Video Editing',
    'Utility',
    'Libraries and Demo',
    'Parenting',
    'Social Networking',
    'Music',
    'Sports',
    'Kids'
  ];

  String? _selectedCategory;

  Future<void> _pickFile(String type) async {
    FilePickerResult? result;

    if (type == 'logo') {
      result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );
    } else if (type == 'apk') {
      result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['apk'],
      );
    } else if (type == 'ipa') {
      result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['ipa'],
      );
    }

    if (result != null && result.files.isNotEmpty) {
      PlatformFile pickedFile = result.files.first;
      setState(() {
        if (type == 'logo') {
          _logo = XFile(pickedFile.path!);
        } else if (type == 'apk') {
          _apkFile = XFile(pickedFile.path!);
        } else if (type == 'ipa') {
          _ipaFile = XFile(pickedFile.path!);
        }
      });
    }
  }

  Future<void> _pickScreenshots() async {
    final pickedFiles = await _picker.pickMultiImage();
    if (pickedFiles.length <= 6) {
      setState(() {
        _screenshots = pickedFiles;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select up to 6 screenshots.')),
      );
    }
  }

  Future<void> _submitProject() async {
    String name = _nameController.text.trim();
    String description = _descriptionController.text.trim();

    if (name.isEmpty ||
        description.isEmpty ||
        description.length < 50 ||
        description.length > 250 ||
        _logo == null ||
        (_apkFile == null && _ipaFile == null) ||
        _screenshots.isEmpty ||
        _screenshots.length > 6 ||
        _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'All fields are mandatory. Description should be between 50 and 250 characters. Select up to 6 screenshots, a category, upload a logo, and at least one APK or IPA file.',
          ),
        ),
      );
      return;
    }

    var crudProject = Provider.of<CRUDProject>(context, listen: false);
    bool isUnique = await crudProject.isProjectNameUnique(name);

    if (!isUnique) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Project name already exists. Please choose a different name.'),
        ),
      );
      return;
    }

    try {
      final logoUrl = _logo != null
          ? await uploadFileToGCS(
              File(_logo!.path), 'project/$name/logos/${_logo!.name}')
          : '';

      String? apkUrl;
      if (_apkFile != null) {
        final apkFile = File(_apkFile!.path);
        apkUrl = await uploadFileToGCS(
            apkFile, 'project/$name/apps/${_apkFile!.name}');
      }

      String? ipaUrl;
      if (_ipaFile != null) {
        final ipaFile = File(_ipaFile!.path);
        ipaUrl = await uploadFileToGCS(
            ipaFile, 'project/$name/apps/${_ipaFile!.name}');
      }

      final List<String> screenshotUrls = await Future.wait(_screenshots.map((screenshot) =>
          crudProject.uploadFile(
              screenshot, 'project/$name/screenshots/${screenshot.name}')));

      Project projectCreation = Project(
        id: '',
        userId: FirebaseAuth.instance.currentUser!.uid.toString(),
        name: name,
        description: description,
        logoUrl: logoUrl,
        screenshotsUrl: screenshotUrls,
        downloadUrl: apkUrl,
        downloadUrlForIphone: ipaUrl,
        status: 'Pending',
        isGraduation: _selectedProject == GraduationProjectType.Yes,
       
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        collaborators: [],
        downloadUrls: {},
     category: _selectedCategory!,
      );

      await crudProject.addItem(projectCreation);

      _nameController.clear();
      _descriptionController.clear();
      setState(() {
        _selectedProject = GraduationProjectType.No;
        _logo = null;
        _apkFile = null;
        _ipaFile = null;
        _screenshots = [];
        _selectedCategory = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Project submitted successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading project: $e')),
      );
      print('Error uploading project: $e');
    }
  }

  Future<String> uploadFileToGCS(File file, String filePath) async {
    final storage = FirebaseStorage.instance;
    final ref = storage.ref().child(filePath);

    try {
      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask.whenComplete(() => null);
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      print('Error uploading file to GCS: $e');
      throw Exception('Error uploading file: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add New Project', style: TextStyle(color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Upload Logo",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Center(
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: _logo != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(
                          File(_logo!.path),
                          fit: BoxFit.cover,
                        ),
                      )
                    : IconButton(
                        icon: Icon(Icons.add_photo_alternate_outlined, size: 40),
                        onPressed: () => _pickFile('logo'),
                      ),
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: "Project Name",
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _descriptionController,
              maxLength: 250,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: "Description",
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.grey[50],
                helperText: 'Between 50 and 250 characters',
                counterText: '${_descriptionController.text.length}/250',
              ),
              onChanged: (text) => setState(() {}),
            ),
            const SizedBox(height: 20),
            Text(
              "Upload App Files",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.android, color: Colors.black87),
                    label: Text("Upload APK"),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.black87,
                      backgroundColor: Colors.grey[200],
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => _pickFile('apk'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.apple, color: Colors.black87),
                    label: Text("Upload IPA"),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.black87,
                      backgroundColor: Colors.grey[200],
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => _pickFile('ipa'),
                  ),
                ),
              ],
            ),
            if (_apkFile != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Selected APK: ${_apkFile!.name}',
                  style: TextStyle(color: Colors.green),
                ),
              ),
            if (_ipaFile != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Selected IPA: ${_ipaFile!.name}',
                  style: TextStyle(color: Colors.green),
                ),
              ),
            const SizedBox(height: 20),
            Text(
              "Category",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              hint: Text('Select Category'),
              value: _selectedCategory,
              isExpanded: true,
              onChanged: (String? newValue) {
                setState(() {
                  _selectedCategory = newValue;
                });
              },
              items: _categories.map((String category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Text(
              "Graduation Project?",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<GraduationProjectType>(
                    title: Text('No'),
                    value: GraduationProjectType.No,
                    groupValue: _selectedProject,
                    onChanged: (GraduationProjectType? value) {
                      if (value != null) {
                        setState(() {
                          _selectedProject = value;
                        });
                      }
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile<GraduationProjectType>(
                    title: Text('Yes'),
                    value: GraduationProjectType.Yes,
                    groupValue: _selectedProject,
                    onChanged: (GraduationProjectType? value) {
                      if (value != null) {
                        setState(() {
                          _selectedProject = value;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Screenshots (${_screenshots.length}/6)",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  icon: Icon(Icons.add_photo_alternate, color: Colors.black87),
                  label: Text("Add Screenshots"),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.black87,
                    backgroundColor: Colors.grey[200],
                  ),
                  onPressed: _pickScreenshots,
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_screenshots.isNotEmpty)
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _screenshots.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(_screenshots[index].path),
                          height: 120,
                          width: 120,
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _submitProject,
                child: Text(
                  "Submit Project",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}