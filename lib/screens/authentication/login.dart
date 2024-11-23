// ignore_for_file: prefer_const_literals_to_create_immutables, prefer_const_constructors, library_private_types_in_public_api, prefer_const_constructors_in_immutables, prefer_interpolation_to_compose_strings, use_build_context_synchronously

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/crudModel/repo_crud.dart';
import '../../core/crudModel/user_crud.dart';
import '../../core/services/auth.dart';
import '../../main.dart';
import 'forgot_password.dart';
import 'signup.dart';

class LoginPage extends StatefulWidget {
  LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isObscure = true;
  @override
  void initState() {
    super.initState();

    _emailController.text = "";
    _passwordController.text = "";
  }

  bool _isValidEmail(String input) {
    return !input.contains('@');
  }

  @override
  Widget build(BuildContext context) {
    var userProvider = Provider.of<CRUDUser>(context);
    var repoProvider = Provider.of<CRUDRepo>(context);

    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
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
          SizedBox(
            width: 200,
            child: TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: "Email",
                labelStyle: TextStyle(
                  color: Color.fromARGB(221, 0, 0, 0), // Label color
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
                suffixText: "@utb.edu.bh",
              ),
              validator: (value) {
                if (!_isValidEmail(value ?? "")) {
                  return 'Please enter a valid email without @';
                }
                return null;
              },
            ),
          ),
          SizedBox(
            width: 200,
            child: TextFormField(
              controller: _passwordController,
              obscureText: _isObscure,
              decoration: InputDecoration(
                labelText: "Password",
                labelStyle: TextStyle(
                  color: Color.fromARGB(221, 0, 0, 0), // Label color
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
          SizedBox(
            height: 20,
          ),
          InkWell(
            child: Padding(
              padding: const EdgeInsets.only(left: 200),
              child: Text("Forgot Password"),
            ),
            onTap: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => ForgotPasswordPage()),
              );
            },
          ),
          SizedBox(
            height: 60,
          ),
          InkWell(
              child: Container(
                width: 150,
                height: 50,
                color: Color.fromARGB(221, 193, 5, 33),
                child: Center(
                  child: Text(
                    "Login",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              // onTap: () async {
              //   var creds = await _authService.loginWithEmail(
              //       "${_emailController.text.trim()}@utb.edu.bh",
              //       _passwordController.text);

              //   if (creds.user != null) {
              //     userProvider.getCurrentUser();
              //     repoProvider.fetchItems();

              //     Navigator.of(context).pushReplacement(
              //       MaterialPageRoute(builder: (context) => MyMain()),
              //     );
              //   } else {
              //     //to do error msg
              //   }
              // },
              onTap: () async {
                try {
                  var creds = await _authService.loginWithEmail(
                      "${_emailController.text.trim()}@utb.edu.bh",
                      _passwordController.text);

                  if (creds.user != null) {
                    userProvider.getCurrentUser();
                    repoProvider.fetchItems();

                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => MyMain()),
                    );
                  }
                } on FirebaseAuthException catch (e) {
                  // Show error message to the user
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Login failed: ${e.message}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                } catch (e) {
                  // Handle any other exceptions
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('An unexpected error occurred'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }),
          SizedBox(
            height: 10,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Don't have an account?"),
              SizedBox(
                width: 5,
              ),
              InkWell(
                child: Text(
                  "Sign up",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                onTap: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => SignUpPage()),
                  );
                },
              )
            ],
          )
        ],
      ),
    );
  }
}
