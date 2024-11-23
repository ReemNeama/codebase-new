// ignore_for_file: use_key_in_widget_constructors, prefer_const_constructors

import '/screens/userProfile/settings.dart';
import 'package:flutter/material.dart';
import 'profile.dart';

class CustomDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.5,
            child: Drawer(
              child: SettingsContent(),
            ),
          ),
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.5,
            child: ProfilePage(),
          ),
        ],
      ),
    );
  }
}
