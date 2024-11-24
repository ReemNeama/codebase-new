// // ignore_for_file: prefer_const_constructors, prefer_const_declarations, sort_child_properties_last, use_build_context_synchronously, prefer_interpolation_to_compose_strings

// import 'package:utb_appstore/screens/export.dart';

// class ForgotPasswordPage extends StatefulWidget {
//   const ForgotPasswordPage({super.key});

//   @override
//   State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
// }

// class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
//   final TextEditingController _emailController = TextEditingController();

//   bool _isValidEmail(String input) {
//     final validSuffix = '@utb.edu.bh';
//     final enteredSuffix = input.substring(input.lastIndexOf('@'));
//     return input.contains('@') && enteredSuffix == validSuffix;
//   }

//   Future passwordReset() async {
//     try {
//       await FirebaseAuth.instance
//           .sendPasswordResetEmail(email: _emailController.text + "@utb.edu.bh")
//           .then(
//         (_) {
//           showDialog(
//               context: context,
//               builder: (context) {
//                 return AlertDialog(
//                   content: Text("Password Reset Link Sent! Check Your Email"),
//                 );
//               });
//         },
//       );
//     } on FirebaseAuthException catch (e) {
//       showDialog(
//           context: context,
//           builder: (context) {
//             return AlertDialog(
//               content: Text(e.message.toString()),
//             );
//           });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Reset Password'),
//         leading: IconButton(
//           icon: Icon(Icons.arrow_back),
//           onPressed: () {
//             Navigator.of(context).push(
//               MaterialPageRoute(builder: (context) => LoginPage()),
//             );
//           },
//         ),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 10),
//         child: Column(
//           children: [
//             Text("Enter your email to recieve password resert link"),
//             SizedBox(
//               width: 200,
//               child: TextFormField(
//                 controller: _emailController,
//                 decoration: InputDecoration(
//                   labelText: "Email",
//                   labelStyle: TextStyle(
//                     color: Color.fromARGB(221, 0, 0, 0), // Label color
//                   ),
//                   enabledBorder: UnderlineInputBorder(
//                     borderSide: BorderSide(
//                         color: Color.fromARGB(221, 0, 0, 0), width: 1),
//                   ),
//                   focusedBorder: UnderlineInputBorder(
//                     borderSide: BorderSide(
//                         color: Color.fromARGB(221, 0, 0, 0), width: 2),
//                   ),
//                   hintText: "bh########",
//                   suffixText: "@utb.edu.bh",
//                 ),
//                 validator: (value) {
//                   if (!_isValidEmail(value ?? "")) {
//                     return 'Please enter a valid UTB email ending with @utb.edu.bh';
//                   }
//                   return null;
//                 },
//               ),
//             ),
//             SizedBox(
//               height: 30,
//             ),
//             MaterialButton(
//               onPressed: passwordReset,
//               child: Text(
//                 "Reset Password",
//                 style: TextStyle(color: Colors.white),
//               ),
//               color: Color.fromARGB(221, 193, 5, 33),
//             )
//           ],
//         ),
//       ),
//     );
//   }
// }
// forgot_password.dart

// ignore_for_file: prefer_const_constructors, prefer_const_declarations, prefer_interpolation_to_compose_strings

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'login.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';

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
              Navigator.of(context).pop(); // Return to login page
            },
          )
        ],
      ),
    );
  }

  Future<void> passwordReset() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    if (_emailController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your email address';
        _isLoading = false;
      });
      return;
    }

    final email = _emailController.text.trim();
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      setState(() {
        _errorMessage = 'Please enter a valid email address';
        _isLoading = false;
      });
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: email,
      );
      _showSuccessDialog("Password reset link sent! Check your email.");
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          _errorMessage = 'No user found for that email.';
          break;
        case 'invalid-email':
          _errorMessage = 'The email address is badly formatted.';
          break;
        default:
          _errorMessage = 'An error occurred. Please try again later.';
      }
      _showErrorDialog(_errorMessage);
    } catch (e) {
      _errorMessage = 'An unexpected error occurred. Please try again later.';
      _showErrorDialog(_errorMessage);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reset Password'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => LoginPage()),
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
              "Enter your email to receive a password reset link",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: "Email",
                hintText: "example@example.com",
                border: OutlineInputBorder(),
              ),
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
                    onPressed: passwordReset,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      padding:
                          EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text("Reset Password"),
                  ),
          ],
        ),
      ),
    );
  }
}
