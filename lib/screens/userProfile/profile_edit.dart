// ignore_for_file: unused_field, prefer_const_constructors_in_immutables, library_private_types_in_public_api, prefer_const_constructors, use_key_in_widget_constructors, prefer_const_literals_to_create_immutables, prefer_const_declarations, avoid_print, prefer_interpolation_to_compose_strings, non_constant_identifier_names, no_leading_underscores_for_local_identifiers, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/crudModel/user_crud.dart';
import '../../core/models/user.dart';

class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({super.key});

  @override
  _ProfileEditPageState createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;
  bool _isLoading = false;
  String? _errorMessage;

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final List<String> _skills = [];
  final List<String> _programmingLanguages = [];

  // Predefined lists
  final List<String> _availableSkills = [
    'UI/UX Design',
    'Web Development',
    'Mobile Development',
    'Database Management',
    'Cloud Computing',
    'DevOps',
    'System Architecture',
    'Project Management',
    'Agile Methodology',
    'Testing & QA'
  ];

  final List<String> _availableProgrammingLanguages = [
    'Dart',
    'Python',
    'JavaScript',
    'Java',
    'C++',
    'C#',
    'Swift',
    'Kotlin',
    'Ruby',
    'PHP'
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final user = context.read<CRUDUser>().currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error loading user data')),
      );
      Navigator.of(context).pop();
      return;
    }

    _firstNameController.text = user.firstName;
    _lastNameController.text = user.lastName;
    _bioController.text = user.bio ?? '';
    _skills.addAll(user.skills);
    _programmingLanguages.addAll(user.programmingLanguages);
  }

  bool _canContinue() {
    switch (_currentStep) {
      case 0:
        return _firstNameController.text.isNotEmpty &&
            _lastNameController.text.isNotEmpty;
      case 1:
        return true; // Bio is optional
      case 2:
        return true; // Skills and programming languages are optional
      default:
        return false;
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all required fields')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userProvider = context.read<CRUDUser>();
      final currentUser = userProvider.currentUser;

      if (currentUser == null) {
        throw Exception('User not found');
      }

      final updatedUser = User(
        id: currentUser.id,
        email: currentUser.email,
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        profileImageUrl: currentUser.profileImageUrl,
        phoneNumber: currentUser.phoneNumber,
        studentId: currentUser.studentId,
        bio: _bioController.text,
        skills: _skills,
        programmingLanguages: _programmingLanguages,
        createdAt: currentUser.createdAt,
        updatedAt: DateTime.now(),
      );

      await userProvider.updateItem(updatedUser, currentUser.id);

      if (!mounted) return;
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                _errorMessage ?? 'An error occurred while updating profile')),
      );
    }
  }

  Widget _buildBasicInfoStep() {
    return Column(
      children: [
        TextFormField(
          controller: _firstNameController,
          decoration: const InputDecoration(labelText: 'First Name *'),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your first name';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _lastNameController,
          decoration: const InputDecoration(labelText: 'Last Name *'),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your last name';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildAdditionalInfoStep() {
    return Column(
      children: [
        TextFormField(
          controller: _bioController,
          decoration: const InputDecoration(labelText: 'Bio'),
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildSkillsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Skills',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: _skills
              .map((skill) => Chip(
                    label: Text(skill),
                    onDeleted: () {
                      setState(() {
                        _skills.remove(skill);
                      });
                    },
                  ))
              .toList(),
        ),
        DropdownButton<String>(
          hint: const Text('Select a skill'),
          isExpanded: true,
          items: _availableSkills
              .where((skill) => !_skills.contains(skill))
              .map((String skill) {
            return DropdownMenuItem<String>(
              value: skill,
              child: Text(skill),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null && !_skills.contains(newValue)) {
              setState(() {
                _skills.add(newValue);
              });
            }
          },
        ),
        const SizedBox(height: 24),
        const Text('Programming Languages',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: _programmingLanguages
              .map((lang) => Chip(
                    label: Text(lang),
                    onDeleted: () {
                      setState(() {
                        _programmingLanguages.remove(lang);
                      });
                    },
                  ))
              .toList(),
        ),
        DropdownButton<String>(
          hint: const Text('Select a programming language'),
          isExpanded: true,
          items: _availableProgrammingLanguages
              .where((lang) => !_programmingLanguages.contains(lang))
              .map((String lang) {
            return DropdownMenuItem<String>(
              value: lang,
              child: Text(lang),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null && !_programmingLanguages.contains(newValue)) {
              setState(() {
                _programmingLanguages.add(newValue);
              });
            }
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<CRUDUser>().currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Edit Profile")),
        body: const Center(
          child: Text('Please log in to edit your profile'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile"),
      ),
      body: Form(
        key: _formKey,
        child: Stepper(
          currentStep: _currentStep,
          onStepContinue: _isLoading
              ? null
              : () {
                  if (_currentStep < 2) {
                    if (_canContinue()) {
                      setState(() => _currentStep++);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                                Text("Please complete all required fields.")),
                      );
                    }
                  } else if (_canContinue()) {
                    _updateProfile();
                  }
                },
          onStepCancel: _isLoading
              ? null
              : () {
                  if (_currentStep > 0) {
                    setState(() => _currentStep--);
                  }
                },
          steps: [
            Step(
              title: const Text('Basic Information'),
              content: _buildBasicInfoStep(),
              isActive: _currentStep >= 0,
            ),
            Step(
              title: const Text('Additional Information'),
              content: _buildAdditionalInfoStep(),
              isActive: _currentStep >= 1,
            ),
            Step(
              title: const Text('Skills & Languages'),
              content: _buildSkillsStep(),
              isActive: _currentStep >= 2,
            ),
          ],
        ),
      ),
    );
  }
}
