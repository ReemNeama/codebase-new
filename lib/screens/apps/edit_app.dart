// ignore_for_file: use_super_parameters, library_private_types_in_public_api, avoid_print, use_build_context_synchronously, prefer_const_constructors

import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/crudModel/project_crud.dart';
import '../../core/models/project.dart';

class EditApp extends StatefulWidget {
  final Project existingProject;

  const EditApp({Key? key, required this.existingProject}) : super(key: key);

  @override
  _EditAppState createState() => _EditAppState();
}

class _EditAppState extends State<EditApp> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  XFile? _logo;
  XFile? _apkFile;
  XFile? _ipaFile;
  List<XFile> _screenshots = [];
  final ImagePicker _picker = ImagePicker();

  String? _selectedCategory;
  bool _isGraduationProject = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.existingProject.name;
    _descriptionController.text = widget.existingProject.description;
    _selectedCategory = widget.existingProject.category;
    _isGraduationProject = widget.existingProject.isGraduation;

    // Debugging information
    print('Existing Project Name: ${widget.existingProject.name}');
    print(
        'Existing Project Description: ${widget.existingProject.description}');
    print('Existing Project Category: ${widget.existingProject.category}');
  }

  Future<void> _pickFile(String type) async {
    FilePickerResult? result;
    if (type == 'logo') {
      result = await FilePicker.platform.pickFiles(type: FileType.image);
    } else if (type == 'apk') {
      result = await FilePicker.platform
          .pickFiles(type: FileType.custom, allowedExtensions: ['apk']);
    } else if (type == 'ipa') {
      result = await FilePicker.platform
          .pickFiles(type: FileType.custom, allowedExtensions: ['ipa']);
    }

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        if (type == 'logo') {
          _logo = XFile(result!.files.first.path!);
        } else if (type == 'apk') {
          _apkFile = XFile(result!.files.first.path!);
        } else if (type == 'ipa') {
          _ipaFile = XFile(result!.files.first.path!);
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
        SnackBar(content: Text('All fields are mandatory.')),
      );
      return;
    }

    final crudProject = Provider.of<CRUDProject>(context, listen: false);
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
      String? logoUrl = _logo != null
          ? await uploadFileToGCS(
              File(_logo!.path), 'projects/$name/logos/${_logo!.name}')
          : widget.existingProject.logoUrl;

      String? downloadUrl = _apkFile != null
          ? await uploadFileToGCS(
              File(_apkFile!.path), 'projects/$name/apps/${_apkFile!.name}')
          : widget.existingProject.downloadUrl;

      String? downloadUrlForIphone = _ipaFile != null
          ? await uploadFileToGCS(
              File(_ipaFile!.path), 'projects/$name/apps/${_ipaFile!.name}')
          : widget.existingProject.downloadUrlForIphone;

      List<String> screenshotUrls = await Future.wait(_screenshots.map(
          (screenshot) => crudProject.uploadFile(
              screenshot, 'projects/$name/screenshots/${screenshot.name}')));

      Project updatedProject = Project(
        id: widget.existingProject.id,
        userId: FirebaseAuth.instance.currentUser!.uid,
        name: name,
        description: description,
        logoUrl: logoUrl,
        screenshotsUrl: screenshotUrls,
        downloadUrl: downloadUrl,
        downloadUrlForIphone: downloadUrlForIphone,
        status: widget.existingProject.status,
        isGraduation: _isGraduationProject,
        createdAt: widget.existingProject.createdAt,
        updatedAt: DateTime.now(),
        collaborators: widget.existingProject.collaborators,
        downloadUrls: widget.existingProject.downloadUrls,
        
        category: _selectedCategory!,
      );

      await crudProject.updateItem(updatedProject, widget.existingProject.id);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Project updated successfully!')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating project: $e')),
      );
      print('Error updating project: $e');
    }
  }

  Future<String> uploadFileToGCS(File file, String filePath) async {
    final storage = FirebaseStorage.instance;
    final ref = storage.ref().child(filePath);
    final uploadTask = ref.putFile(file);
    final snapshot = await uploadTask.whenComplete(() => null);
    return await snapshot.ref.getDownloadURL();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Project'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Upload Logo"),
              IconButton(
                icon: Icon(Icons.image),
                onPressed: () => _pickFile('logo'),
              ),
              if (_logo != null) Image.file(File(_logo!.path), height: 100),
              SizedBox(height: 10),
              Text("Project Name"),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(labelText: "Project Name"),
              ),
              SizedBox(height: 10),
              Text("Description"),
              TextField(
                controller: _descriptionController,
                maxLength: 250,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: "Description",
                  counterText: '${_descriptionController.text.length}/250',
                ),
              ),
              SizedBox(height: 10),
              Text("Upload APK/IPA"),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () => _pickFile('apk'),
                    child: Text("Upload APK"),
                  ),
                  SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () => _pickFile('ipa'),
                    child: Text("Upload IPA"),
                  ),
                ],
              ),
              if (_apkFile != null) Text('APK: ${_apkFile!.name}'),
              if (_ipaFile != null) Text('IPA: ${_ipaFile!.name}'),
              SizedBox(height: 10),
              Text("Screenshots"),
              ElevatedButton(
                onPressed: _pickScreenshots,
                child: Text("Select Screenshots"),
              ),
              if (_screenshots.isNotEmpty) ...[
                for (var screenshot in _screenshots)
                  Image.file(File(screenshot.path), height: 100),
              ],
              SizedBox(height: 10),
              Text("Category"),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                hint: Text("Select Category"),
                items: [
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
                  'Utility',
                  'Libraries and Demo',
                  'Parenting',
                  'Social Networking',
                  'Music',
                  'Sports',
                  'Kids',
                ].map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                  });
                },
              ),
              SizedBox(height: 10),
              Text("Graduation Project"),
              Row(
                children: [
                  Radio<bool>(
                    value: true,
                    groupValue: _isGraduationProject,
                    onChanged: (value) =>
                        setState(() => _isGraduationProject = value!),
                  ),
                  Text("Yes"),
                  Radio<bool>(
                    value: false,
                    groupValue: _isGraduationProject,
                    onChanged: (value) =>
                        setState(() => _isGraduationProject = value!),
                  ),
                  Text("No"),
                ],
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitProject,
                child: Text("Update Project"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
