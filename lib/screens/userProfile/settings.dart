// ignore_for_file: prefer_const_constructors, prefer_const_constructors_in_immutables, library_private_types_in_public_api

import '/screens/authentication/login.dart';
import '/screens/terms.dart';
import '/screens/userProfile/profile_edit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/services/auth.dart';
import '../authentication/change_password.dart';

class SettingsContent extends StatelessWidget {
  const SettingsContent({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(title: 'Account'),
            SettingItem(
              title: 'Edit profile',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (context) => const ProfileEditPage()),
                );
              },
            ),
            SettingItem(
              title: 'Change password',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => ChangePasswordPage()),
                );
              },
            ),
            SizedBox(height: 16.h),
            SectionHeader(title: 'Notifications'),
            NotificationItem(title: 'Notifications'),
            NotificationItem(title: 'App notifications', isSwitchOn: true),
            SizedBox(height: 16.h),
            SectionHeader(title: 'More'),
            SettingItem(title: 'Language'),
            SettingItem(
              title: 'Terms & Conditions',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (context) => TermsAndConditionsPage()),
                );
              },
            ),
            SizedBox(height: 32.h),
            Center(
              child: LogoutButton(),
            ),
          ],
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;

  SectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class SettingItem extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;

  SettingItem({super.key, required this.title, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 0),
      title: Text(title),
      trailing: Icon(Icons.arrow_forward_ios),
      onTap: onTap,
    );
  }
}

class NotificationItem extends StatefulWidget {
  final String title;
  final bool isSwitchOn;

  NotificationItem({super.key, required this.title, this.isSwitchOn = false});

  @override
  _NotificationItemState createState() => _NotificationItemState();
}

class _NotificationItemState extends State<NotificationItem> {
  bool _isSwitchOn = false;

  @override
  void initState() {
    super.initState();
    _isSwitchOn = widget.isSwitchOn;
  }

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 0),
      title: Text(widget.title),
      value: _isSwitchOn,
      onChanged: (value) {
        setState(() {
          _isSwitchOn = value;
        });
      },
    );
  }
}

class LogoutButton extends StatelessWidget {
  const LogoutButton({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();

    return ElevatedButton.icon(
      onPressed: () {
        authService.signOut();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => LoginPage()),
        );
      },
      icon: Icon(Icons.logout),
      label: Text('Logout'),
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Colors.red,
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30.r),
        ),
      ),
    );
  }
}
