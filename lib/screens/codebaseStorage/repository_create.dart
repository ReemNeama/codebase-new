// ignore_for_file: prefer_const_constructors, use_build_context_synchronously

import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../core/crudModel/repo_crud.dart';
import '../../core/crudModel/user_crud.dart';
import '../../core/models/repo.dart';
import '../../core/models/user.dart' as app_user;

class RepositoryPage extends StatefulWidget {
  const RepositoryPage({super.key});

  @override
  State<RepositoryPage> createState() => _RepositoryPageState();
}

class _RepositoryPageState extends State<RepositoryPage> {
  final TextEditingController _repoController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  List<app_user.User> collabUsers = [];
  app_user.User? _selectedUser;
  bool? private = false; // Set default to false (Public)
  String pripub = "Public"; // Set default to "Public"
  final List<String> _selectedLanguages = [];
  final List<String> _selectedCategory = [];
  final _storage = FirebaseStorage.instance.ref('repository/');

  final categories = [
    'Web',
    'Mobile',
    'AI',
    'Data Science',
    'Game Development'
  ];

  final languages = [
    'JavaScript',
    'Python',
    'Java',
    'C++',
    'Ruby',
    'Swift',
    'Kotlin',
    'Go',
    'Rust',
    'PHP',
    'TypeScript',
    'C#',
    'Shell',
    'C',
    'Scala',
    'Dart',
    'HTML',
    'CSS'
  ];

  @override
  Widget build(BuildContext context) {
    var repoProvider = Provider.of<CRUDRepo>(context);
    var userProvider = Provider.of<CRUDUser>(context);

    // Check if user is logged in
    if (userProvider.currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Add Repository')),
        body: Center(
          child: Text('Please log in to create a repository'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Add Repository'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(20.0.sp),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Repository Details',
                style: TextStyle(
                  fontSize: 20.0.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 20.0.h),
              _buildTextFormField(
                controller: _repoController,
                labelText: 'Repository Name',
              ),
              SizedBox(height: 16.0.h),
              _buildTextFormField(
                controller: _descriptionController,
                labelText: 'Description',
                maxLines: 3,
              ),
              SizedBox(height: 16.0.h),
              _buildLanguagesSelection(),
              SizedBox(height: 16.0.h),
              _buildCategoriesSelection(),
              SizedBox(height: 16.0.h),
              _buildPrivacyOptions(),
              SizedBox(height: 16.0.h),
              _buildCollaboratorDropdown(userProvider),
              SizedBox(height: 16.0.h),
              _buildAddButton(),
              SizedBox(height: 16.0.h),
              if (collabUsers.isNotEmpty) _buildCollaboratorList(),
              _buildAddRepositoryButton(repoProvider),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        border: OutlineInputBorder(),
        contentPadding:
            EdgeInsets.symmetric(horizontal: 12.0.sp, vertical: 8.0.sp),
      ),
      maxLines: maxLines,
    );
  }

  Widget _buildLanguagesSelection() {
    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      children: languages.map((String language) {
        final isSelected = _selectedLanguages.contains(language);
        return FilterChip(
          label: Text(language),
          selected: isSelected,
          onSelected: (bool selected) {
            setState(() {
              if (selected) {
                _selectedLanguages.add(language);
              } else {
                _selectedLanguages.remove(language);
              }
            });
          },
          selectedColor: Colors.red.withOpacity(0.25),
          checkmarkColor: Colors.red,
        );
      }).toList(),
    );
  }

  Widget _buildCategoriesSelection() {
    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      children: categories.map((String category) {
        final isSelected = _selectedCategory.contains(category);
        return FilterChip(
          label: Text(category),
          selected: isSelected,
          onSelected: (bool selected) {
            setState(() {
              if (selected) {
                _selectedCategory.add(category);
              } else {
                _selectedCategory.remove(category);
              }
            });
          },
          selectedColor: Colors.red.withOpacity(0.25),
          checkmarkColor: Colors.red,
        );
      }).toList(),
    );
  }

  Widget _buildPrivacyOptions() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: Colors.black),
      ),
      child: Row(
        children: [
          Expanded(
            child: RadioListTile(
              title: Text('Private'),
              value: true,
              groupValue: private,
              onChanged: (value) {
                setState(() {
                  private = value;
                  pripub = "Private";
                });
              },
              activeColor: Colors.red,
            ),
          ),
          Expanded(
            child: RadioListTile(
              title: Text('Public'),
              value: false,
              groupValue: private,
              onChanged: (value) {
                setState(() {
                  private = value;
                  pripub = "Public";
                });
              },
              activeColor: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollaboratorDropdown(CRUDUser userProvider) {
    final currentUserStudentId = userProvider.currentUser?.studentId;

    return FutureBuilder<List<app_user.User>>(
      future: userProvider.fetchItems(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error fetching users'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('No users available'));
        } else {
          // Filter out users that are already collaborators or the current user
          final availableUsers = snapshot.data!.where((user) {
            final userStudentId = user.studentId;
            if (userStudentId == null) {
              return false;
            }

            return !collabUsers
                    .any((collab) => collab.studentId == userStudentId) &&
                userStudentId != currentUserStudentId;
          }).toList();

          if (availableUsers.isEmpty) {
            return Center(child: Text('No available collaborators'));
          }

          return DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: 'Select Collaborator',
              border: OutlineInputBorder(),
            ),
            value: _selectedUser?.studentId,
            onChanged: (String? newValue) {
              if (newValue != null) {
                final selectedUser = availableUsers.firstWhere(
                  (user) => user.studentId == newValue,
                  orElse: () => app_user.User.empty(),
                );
                setState(() {
                  _selectedUser = selectedUser;
                });
              }
            },
            items: availableUsers.map<DropdownMenuItem<String>>((user) {
              final studentId = user.studentId;
              if (studentId == null) {
                return DropdownMenuItem<String>(
                  value: '',
                  child: Text('Invalid User'),
                );
              }

              return DropdownMenuItem<String>(
                value: studentId,
                child: Text('${user.name} ($studentId)'),
              );
            }).toList(),
            hint: Text('Select a collaborator'),
            isExpanded: true,
          );
        }
      },
    );
  }

  Widget _buildAddButton() {
    return ElevatedButton(
      onPressed: () {
        if (_selectedUser != null &&
            _selectedUser?.studentId != null &&
            !collabUsers
                .any((user) => user.studentId == _selectedUser?.studentId)) {
          setState(() {
            collabUsers.add(_selectedUser!);
            _selectedUser = null;
          });
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(vertical: 10.0.sp),
      ),
      child: Text("Add"),
    );
  }

  Widget _buildCollaboratorList() {
    return SizedBox(
      height: 200.h,
      child: ListView.builder(
        itemCount: collabUsers.length,
        itemBuilder: (context, index) {
          final user = collabUsers[index];
          return ListTile(
            title: Text(user.name),
            subtitle: Text(user.studentId ?? 'No ID'),
            trailing: IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                setState(() {
                  collabUsers.removeAt(index);
                });
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildAddRepositoryButton(CRUDRepo repoProvider) {
    return ElevatedButton(
      onPressed: () async {
        if (_repoController.text.isEmpty ||
            _descriptionController.text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Please fill in all required fields')),
          );
          return;
        }

        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Please log in to create a repository')),
          );
          return;
        }

        final folderLocation = _storage.child(_repoController.text.trim());

        try {
          final repo = Repo(
            id: '',
            storageUrl: folderLocation.toString(),
            userId: currentUser.uid,
            name: _repoController.text.trim(),
            description: _descriptionController.text.trim(),
            languages: _selectedLanguages,
            categories: _selectedCategory,
            files: [],
            status: pripub,
            collabs: collabUsers
                .map((e) => e.studentId ?? '')
                .where((id) => id.isNotEmpty)
                .toList(),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          await repoProvider.addItem(repo);
          Navigator.pop(context);
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error creating repository: $e')),
          );
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(vertical: 10),
      ),
      child: Text("Create Repository"),
    );
  }
}
