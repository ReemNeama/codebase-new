// ignore_for_file: use_super_parameters, library_private_types_in_public_api, prefer_const_constructors, use_build_context_synchronously, deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../core/crudModel/repo_crud.dart';
import '../../core/crudModel/user_crud.dart';
import '../../core/models/repo.dart';
import '../../core/models/user.dart';

class EditRepositoryPage extends StatefulWidget {
  final Repo repository;

  const EditRepositoryPage({Key? key, required this.repository})
      : super(key: key);

  @override
  _EditRepositoryPageState createState() => _EditRepositoryPageState();
}

class _EditRepositoryPageState extends State<EditRepositoryPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final List<String> _selectedLanguages = [];
  final List<String> _selectedCategory = [];

  bool _isLoading = false;
  bool _hasChanges = false;
  bool? private;
  String status = "";
  List<User> collaborators = [];
  User? _selectedUser;

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

  final categories = [
    'Web',
    'Mobile',
    'AI',
    'Data Science',
    'Game Development'
  ];

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.repository.name;
    _descriptionController.text = widget.repository.description;
    _selectedLanguages.addAll(widget.repository.languages);
    _selectedCategory.addAll(widget.repository.categories);
    status = widget.repository.status;
    private = status == "private";

    // Listen for changes
    _nameController.addListener(_onFieldChanged);
    _descriptionController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard Changes?'),
        content: const Text(
            'You have unsaved changes. Do you want to discard them?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    var repoProvider = Provider.of<CRUDRepo>(context);
    var userProvider = Provider.of<CRUDUser>(context);

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Edit Repository'),
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(20.0.sp),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Edit Repository Details',
                    style: TextStyle(
                      fontSize: 20.0.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 20.0.h),
                  _buildTextFormField(
                    controller: _nameController,
                    labelText: 'Repository Name',
                  ),
                  SizedBox(height: 16.0.h),
                  _buildTextFormField(
                    controller: _descriptionController,
                    labelText: 'Description',
                    maxLines: 3,
                  ),
                  SizedBox(height: 16.0.h),
                  _buildLanguagesField(),
                  SizedBox(height: 16.0.h),
                  _buildCategoriesField(),
                  SizedBox(height: 16.0.h),
                  _buildPrivacyOptions(),
                  SizedBox(height: 16.0.h),
                  _buildCollaboratorDropdown(userProvider),
                  SizedBox(height: 16.0.h),
                  _buildCollaboratorList(),
                  SizedBox(height: 16.0.h),
                  _buildUpdateButton(repoProvider),
                ],
              ),
            ),
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
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a value';
        }
        return null;
      },
    );
  }

  Widget _buildLanguagesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Languages',
          style: TextStyle(fontSize: 16.0.sp),
        ),
        SizedBox(height: 8.0.h),
        Wrap(
          spacing: 8.0.sp,
          children: languages
              .map((language) => _buildLanguageChip(language))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildLanguageChip(String language) {
    return ChoiceChip(
      label: Text(language),
      selected: _selectedLanguages.contains(language),
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _selectedLanguages.add(language);
          } else {
            _selectedLanguages.remove(language);
          }
        });
      },
    );
  }

  Widget _buildCategoriesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Categories',
          style: TextStyle(fontSize: 16.0.sp),
        ),
        SizedBox(height: 8.0.h),
        Wrap(
          spacing: 8.0.sp,
          children: categories
              .map((category) => _buildCategoryChip(category))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildCategoryChip(String category) {
    return ChoiceChip(
      label: Text(category),
      selected: _selectedCategory.contains(category),
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _selectedCategory.add(category);
          } else {
            _selectedCategory.remove(category);
          }
        });
      },
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
                  status = "private";
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
                  status = "public";
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
    return FutureBuilder<List<User>>(
      future: userProvider.fetchItems(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Text('No users found');
        }

        final users = snapshot.data!;
        final filteredUsers = users
            .where((user) =>
                !collaborators
                    .any((collab) => collab.studentId == user.studentId) &&
                user.studentId != null &&
                user.studentId!.isNotEmpty)
            .toList();

        return DropdownButtonFormField<String>(
          value: _selectedUser?.studentId,
          onChanged: (String? newValue) {
            setState(() {
              _selectedUser = users.firstWhere(
                (user) => user.studentId == newValue,
                orElse: () => User.empty(),
              );
            });
          },
          items: filteredUsers.map<DropdownMenuItem<String>>((User user) {
            return DropdownMenuItem<String>(
              value: user.studentId,
              child: Text('${user.firstName} ${user.lastName}'),
            );
          }).toList(),
          decoration: InputDecoration(
            labelText: 'Select Collaborator',
            border: OutlineInputBorder(),
          ),
        );
      },
    );
  }

  Widget _buildCollaboratorList() {
    return SizedBox(
      height: 200.h,
      child: ListView.builder(
        itemCount: collaborators.length,
        itemBuilder: (context, index) {
          final user = collaborators[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              child: Text(user.firstName.isNotEmpty ? user.firstName[0] : '?'),
            ),
            title: Text('${user.firstName} ${user.lastName}'),
            subtitle: Text(user.studentId ?? ''),
            trailing: IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                setState(() {
                  collaborators.removeAt(index);
                });
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildUpdateButton(CRUDRepo repoProvider) {
    return ElevatedButton(
      onPressed: () async {
        if (_formKey.currentState!.validate()) {
          if (_selectedUser != null && _selectedUser!.studentId != null) {
            setState(() {
              collaborators.add(_selectedUser!);
              _selectedUser = null;
            });
          }
          // Create updated Repo object
          final updatedRepo = Repo(
            id: widget.repository.id,
            storageUrl: widget.repository.storageUrl,
            userId: widget.repository.userId,
            name: _nameController.text,
            description: _descriptionController.text.trim(),
            languages: _selectedLanguages,
            categories: _selectedCategory,
            status: status,
            collabs: collaborators
                .map((e) => e.studentId ?? '')
                .where((id) => id.isNotEmpty)
                .toList(),
            createdAt: widget.repository.createdAt,
            updatedAt: DateTime.now(),
          );

          setState(() => _isLoading = true);
          await repoProvider.updateItem(updatedRepo, widget.repository.id);
          setState(() => _isLoading = false);
          Navigator.pop(context);
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        padding: EdgeInsets.all(12.0.sp),
      ),
      child: _isLoading
          ? CircularProgressIndicator(color: Colors.white)
          : Text('Update Repository'),
    );
  }
}
