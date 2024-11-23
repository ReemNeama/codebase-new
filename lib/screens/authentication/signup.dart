// ignore_for_file: unused_field, prefer_const_constructors_in_immutables, library_private_types_in_public_api, prefer_const_constructors, use_key_in_widget_constructors, prefer_const_literals_to_create_immutables, prefer_const_declarations, avoid_print, prefer_interpolation_to_compose_strings, non_constant_identifier_names, no_leading_underscores_for_local_identifiers, use_build_context_synchronously

import 'dart:io';
import '/screens/homepage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/services/auth.dart';
import '../../core/services/storage_service.dart';
import 'login.dart';

class SignUpPage extends StatefulWidget {
  SignUpPage({super.key});

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;
  bool _isLoading = false;
  String? _errorMessage;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _studentIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  File? _profileImage;
  bool _isObscure = true;
  bool _isObscureConfirm = true;

  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    // Add listener to email controller to update student ID
    _emailController.addListener(_updateStudentId);
  }

  @override
  void dispose() {
    _emailController.removeListener(_updateStudentId);
    _emailController.dispose();
    _studentIdController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _bioController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }

  void _updateStudentId() {
    String email = _emailController.text.toLowerCase();
    // Extract student ID from email if it matches the pattern
    if (email.contains('@')) {
      String studentId = email.split('@')[0];
      _studentIdController.text = studentId;
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _profileImage = File(image.path);
      });
    }
  }

  bool _canContinue() {
    switch (_currentStep) {
      case 0:
        return _studentIdController.text.isNotEmpty &&
            _firstNameController.text.isNotEmpty &&
            _lastNameController.text.isNotEmpty;
      case 1:
        return _passwordController.text.isNotEmpty &&
            _confirmPasswordController.text.isNotEmpty &&
            _passwordController.text == _confirmPasswordController.text;
      case 2:
        return _profileImage != null;
      default:
        return false;
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate() || _profileImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Please complete all fields and select a profile picture')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Create user account
      final userCredential = await _authService.signupWithEmail(
        _studentIdController.text + "@utb.edu.bh",
        _passwordController.text,
      );

      // 2. Upload profile picture
      final String profilePictureUrl =
          await _storageService.uploadProfilePicture(
        userCredential.user!.uid,
        _profileImage!,
      );

      // 3. Create user profile in Firestore
      await _firestore
          .collection('profiles')
          .doc(userCredential.user!.uid)
          .set({
        'email': _studentIdController.text + "@utb.edu.bh",
        'firstName': _firstNameController.text,
        'lastName': _lastNameController.text,
        'studentId': _studentIdController.text,
        'profileImageUrl': profilePictureUrl,
        'phoneNumber': _phoneNumberController.text.isNotEmpty ? _phoneNumberController.text : null,
        'bio': _bioController.text.isNotEmpty ? _bioController.text : null,
        'skills': [],  // Initialize as empty list, can be updated later
        'programmingLanguages': [],  // Initialize as empty list, can be updated later
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 4. Navigate to user details page
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => HomePage(),
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(_errorMessage ?? 'An error occurred during registration')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Sign Up"),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => LoginPage()),
            );
          },
        ),
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
                            content: Text(
                                "Please complete all required fields correctly.")),
                      );
                    }
                  } else if (_canContinue()) {
                    _register();
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
              title: const Text('Student ID'),
              content: _buildStudentIdStep(),
              isActive: _currentStep >= 0,
            ),
            Step(
              title: const Text('Password'),
              content: _buildPasswordStep(),
              isActive: _currentStep >= 1,
            ),
            Step(
              title: const Text('Profile Picture'),
              content: _buildProfilePictureStep(),
              isActive: _currentStep >= 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentIdStep() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 120,
              child: Image(image: AssetImage('lib/asset/logo.png')),
            ),
            Text(
              "UTB \nCodeBase",
              style: TextStyle(
                fontSize: 35,
                fontWeight: FontWeight.bold,
              ),
            )
          ],
        ),
        SizedBox(height: 20),
        SizedBox(
          width: 300,
          child: TextFormField(
            controller: _studentIdController,
            decoration: InputDecoration(
              labelText: "Student ID",
              labelStyle: TextStyle(
                color: Color.fromARGB(221, 0, 0, 0),
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide:
                    BorderSide(color: Color.fromARGB(221, 0, 0, 0), width: 1),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide:
                    BorderSide(color: Color.fromARGB(221, 0, 0, 0), width: 2),
              ),
              hintText: "bh########",
            ),
            onChanged: (value) {
              // Update email when student ID changes
              setState(() {
                _emailController.text = value;
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your student ID';
              }
              if (!value.toLowerCase().startsWith('bh')) {
                return 'Student ID must start with "bh"';
              }
              if (value.length != 10) {
                return 'Student ID must be 10 characters long';
              }
              return null;
            },
          ),
        ),
        SizedBox(height: 10),
        SizedBox(
          width: 300,
          child: TextFormField(
            controller: _firstNameController,
            decoration: InputDecoration(
              labelText: "First Name",
              labelStyle: TextStyle(
                color: Color.fromARGB(221, 0, 0, 0),
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide:
                    BorderSide(color: Color.fromARGB(221, 0, 0, 0), width: 1),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide:
                    BorderSide(color: Color.fromARGB(221, 0, 0, 0), width: 2),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your first name';
              }
              return null;
            },
          ),
        ),
        SizedBox(height: 10),
        SizedBox(
          width: 300,
          child: TextFormField(
            controller: _lastNameController,
            decoration: InputDecoration(
              labelText: "Last Name",
              labelStyle: TextStyle(
                color: Color.fromARGB(221, 0, 0, 0),
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide:
                    BorderSide(color: Color.fromARGB(221, 0, 0, 0), width: 1),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide:
                    BorderSide(color: Color.fromARGB(221, 0, 0, 0), width: 2),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your last name';
              }
              return null;
            },
          ),
        ),
        SizedBox(height: 10),
        SizedBox(
          width: 300,
          child: TextFormField(
            controller: _emailController,
            enabled: false,
            decoration: InputDecoration(
              labelText: "Email",
              labelStyle: TextStyle(
                color: Color.fromARGB(221, 0, 0, 0),
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide:
                    BorderSide(color: Color.fromARGB(221, 0, 0, 0), width: 1),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide:
                    BorderSide(color: Color.fromARGB(221, 0, 0, 0), width: 2),
              ),
              suffixText: "@utb.edu.bh",
            ),
          ),
        ),
        SizedBox(height: 10),
        SizedBox(
          width: 300,
          child: TextFormField(
            controller: _phoneNumberController,
            decoration: InputDecoration(
              labelText: "Phone Number",
              labelStyle: TextStyle(
                color: Color.fromARGB(221, 0, 0, 0),
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide:
                    BorderSide(color: Color.fromARGB(221, 0, 0, 0), width: 1),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide:
                    BorderSide(color: Color.fromARGB(221, 0, 0, 0), width: 2),
              ),
            ),
          ),
        ),
        SizedBox(height: 10),
        SizedBox(
          width: 300,
          child: TextFormField(
            controller: _bioController,
            decoration: InputDecoration(
              labelText: "Bio",
              labelStyle: TextStyle(
                color: Color.fromARGB(221, 0, 0, 0),
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide:
                    BorderSide(color: Color.fromARGB(221, 0, 0, 0), width: 1),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide:
                    BorderSide(color: Color.fromARGB(221, 0, 0, 0), width: 2),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordStep() {
    return Column(
      children: [
        SizedBox(
          width: 300,
          child: TextFormField(
            controller: _passwordController,
            obscureText: _isObscure,
            decoration: InputDecoration(
              labelText: "Password",
              labelStyle: TextStyle(
                color: Color.fromARGB(221, 0, 0, 0),
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide:
                    BorderSide(color: Color.fromARGB(221, 0, 0, 0), width: 1),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide:
                    BorderSide(color: Color.fromARGB(221, 0, 0, 0), width: 2),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _isObscure ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    _isObscure = !_isObscure;
                  });
                },
              ),
            ),
          ),
        ),
        SizedBox(height: 20),
        SizedBox(
          width: 300,
          child: TextFormField(
            controller: _confirmPasswordController,
            obscureText: _isObscureConfirm,
            decoration: InputDecoration(
              labelText: "Confirm Password",
              labelStyle: TextStyle(
                color: Color.fromARGB(221, 0, 0, 0),
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide:
                    BorderSide(color: Color.fromARGB(221, 0, 0, 0), width: 1),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide:
                    BorderSide(color: Color.fromARGB(221, 0, 0, 0), width: 2),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _isObscureConfirm ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    _isObscureConfirm = !_isObscureConfirm;
                  });
                },
              ),
            ),
            validator: (value) {
              if (value != _passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProfilePictureStep() {
    return Column(
      children: [
        if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              _errorMessage!,
              style: TextStyle(color: Colors.red),
            ),
          ),
        SizedBox(height: 20),
        CircleAvatar(
          radius: 60,
          backgroundColor: Colors.grey[200],
          backgroundImage:
              _profileImage != null ? FileImage(_profileImage!) : null,
          child: _profileImage == null
              ? Icon(
                  Icons.person,
                  size: 60,
                  color: Colors.grey[800],
                )
              : null,
        ),
        SizedBox(height: 20),
        ElevatedButton(
          onPressed: _isLoading ? null : _pickImage,
          child: Text(
              _isLoading ? 'Creating Account...' : 'Select Profile Picture'),
        ),
        if (_isLoading)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: CircularProgressIndicator(),
          ),
      ],
    );
  }
}
