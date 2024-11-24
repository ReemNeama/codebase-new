// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../core/auth/auth_provider.dart';
import 'login.dart';
import 'auth_wrapper.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;
  bool _isLoading = false;
  String? _errorMessage;
  File? _profileImage;
  bool _isObscure = true;
  bool _isObscureConfirm = true;

  late final Map<String, TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = {
      'email': TextEditingController()..addListener(_updateStudentId),
      'studentId': TextEditingController(),
      'password': TextEditingController(),
      'confirmPassword': TextEditingController(),
      'firstName': TextEditingController(),
      'lastName': TextEditingController(),
      'bio': TextEditingController(),
      'phoneNumber': TextEditingController(),
    };
  }

  @override
  void dispose() {
    _controllers['email']?.removeListener(_updateStudentId);
    _controllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  void _updateStudentId() {
    final email = _controllers['email']?.text.toLowerCase() ?? '';
    if (email.contains('@')) {
      _controllers['studentId']?.text = email.split('@')[0];
    }
  }

  Future<void> _pickImage() async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _profileImage = File(image.path));
    }
  }

  bool _canContinue() {
    return switch (_currentStep) {
      0 => _controllers['studentId']?.text.isNotEmpty == true &&
          _controllers['firstName']?.text.isNotEmpty == true &&
          _controllers['lastName']?.text.isNotEmpty == true,
      1 => _controllers['password']?.text.isNotEmpty == true &&
          _controllers['confirmPassword']?.text.isNotEmpty == true &&
          _controllers['password']?.text ==
              _controllers['confirmPassword']?.text,
      2 => _profileImage != null,
      _ => false
    };
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
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // 1. Create user account
      await authProvider.signUpWithEmailAndPassword(
          "${_controllers['studentId']!.text}@utb.edu.bh", "");
      //TODO

      final user = authProvider.state.user;
      if (user == null) throw Exception('Failed to create user account');

      // 2. Upload profile picture

      // 3. Create user profile in Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'email': "${_controllers['studentId']?.text}@utb.edu.bh",
        'firstName': _controllers['firstName']?.text,
        'lastName': _controllers['lastName']?.text,
        'studentId': _controllers['studentId']?.text,
        'profileImageUrl': "",
        'phoneNumber': _controllers['phoneNumber']!.text.isNotEmpty
            ? _controllers['phoneNumber']?.text
            : null,
        'bio': _controllers['bio']!.text.isNotEmpty
            ? _controllers['bio']?.text
            : null,
        'skills': [], // Initialize as empty list, can be updated later
        'programmingLanguages':
            [], // Initialize as empty list, can be updated later
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 4. Navigate to home page through AuthWrapper
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const AuthWrapper(),
        ),
        (route) => false,
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
            controller: _controllers['studentId'],
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
              setState(() {
                _controllers['email']?.text = value;
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
            controller: _controllers['firstName'],
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
            controller: _controllers['lastName'],
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
            controller: _controllers['email'],
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
            controller: _controllers['phoneNumber'],
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
            controller: _controllers['bio'],
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
            controller: _controllers['password'],
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
            controller: _controllers['confirmPassword'],
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
              if (value != _controllers['password']?.text) {
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
