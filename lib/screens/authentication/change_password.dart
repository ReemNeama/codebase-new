// ignore_for_file: use_super_parameters, prefer_const_constructors

import '/main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({Key? key}) : super(key: key);

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _isLoading = false;
  bool _passwordVisible = false;
  String _errorMessage = '';
  String _passwordStrength = '';

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('An Error Occurred'),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: Text('Okay'),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          )
        ],
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Success'),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: Text('Okay'),
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
          )
        ],
      ),
    );
  }

  void _checkPasswordStrength(String password) {
    if (password.length < 6) {
      setState(() {
        _passwordStrength = "Weak";
      });
    } else if (password.length < 10) {
      setState(() {
        _passwordStrength = "Medium";
      });
    } else {
      setState(() {
        _passwordStrength = "Strong";
      });
    }
  }

  Future<void> changePassword() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    User? user = FirebaseAuth.instance.currentUser;

    if (user != null && _oldPasswordController.text.isNotEmpty) {
      try {
        AuthCredential credential = EmailAuthProvider.credential(
          email: user.email!,
          password: _oldPasswordController.text,
        );

        await user.reauthenticateWithCredential(credential);

        if (_newPasswordController.text != _confirmPasswordController.text) {
          setState(() {
            _errorMessage = "Passwords do not match.";
          });
        } else if (_newPasswordController.text.isNotEmpty) {
          await user.updatePassword(_newPasswordController.text);
          _showSuccessDialog("Password changed successfully!");
        } else {
          setState(() {
            _errorMessage = 'Please enter a new password';
          });
        }
      } on FirebaseAuthException catch (e) {
        switch (e.code) {
          case 'wrong-password':
            _errorMessage = 'The old password is incorrect.';
            break;
          case 'weak-password':
            _errorMessage = 'The new password is too weak.';
            break;
          default:
            _errorMessage = 'An error occurred. Please try again later.';
        }
        _showErrorDialog(_errorMessage);
      } catch (e) {
        _errorMessage = 'An unexpected error occurred. Please try again later.';
        _showErrorDialog(_errorMessage);
      }
    } else {
      setState(() {
        _errorMessage = 'Please enter your current password.';
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Change Password'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => MyApp()),
            );
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Enter your current and new password",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            TextFormField(
              controller: _oldPasswordController,
              decoration: InputDecoration(
                labelText: "Current Password",
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            SizedBox(height: 20),
            TextFormField(
              controller: _newPasswordController,
              onChanged: _checkPasswordStrength,
              decoration: InputDecoration(
                labelText: "New Password",
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _passwordVisible ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _passwordVisible = !_passwordVisible;
                    });
                  },
                ),
              ),
              obscureText: !_passwordVisible,
            ),
            SizedBox(height: 10),
            Text(
              "Password Strength: $_passwordStrength",
              style: TextStyle(
                color: _passwordStrength == 'Weak'
                    ? Colors.red
                    : _passwordStrength == 'Medium'
                        ? Colors.orange
                        : Colors.green,
              ),
            ),
            SizedBox(height: 20),
            TextFormField(
              controller: _confirmPasswordController,
              decoration: InputDecoration(
                labelText: "Confirm New Password",
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            SizedBox(height: 20),
            if (_errorMessage.isNotEmpty)
              Text(
                _errorMessage,
                style: TextStyle(color: Colors.red),
              ),
            SizedBox(height: 20),
            _isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: changePassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color.fromARGB(221, 193, 5, 33),
                      padding:
                          EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    ),
                    child: Text("Change Password"),
                  ),
          ],
        ),
      ),
    );
  }
}
