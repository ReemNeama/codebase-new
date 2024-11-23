import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../core/crudModel/user_crud.dart';
import '../../core/models/user.dart';
import '../homepage.dart';
import '../apps/app_store.dart';
import '../codebaseStorage/repository_list.dart';
import '../codebaseStorage/repository_create.dart';
import '../myProjects/my_projects.dart';
import '../userProfile/profile.dart';
import '../userProfile/settings.dart';
import 'login.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User?>(
      future: Provider.of<CRUDUser>(context, listen: false)
          .getCurrentUser()
          .catchError((error) {
        // If getCurrentUser throws an error (user not logged in), return null
        return null;
      }),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError) {
          return LoginPage();
        } else if (snapshot.hasData && snapshot.data != null) {
          return const MainLayout();
        } else {
          return LoginPage();
        }
      },
    );
  }
}

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 2;

  final List<Widget> _pages = [
    const AppStorePage(),
    const RepositoryPage(),
    const HomePage(),
    const MyProjects(),
    const ProfilePage(),
  ];

  AppBar _buildAppBar(BuildContext context) {
    String title;
    switch (_selectedIndex) {
      case 0:
        title = 'App Store';
        break;
      case 1:
        title = 'Codebase';
        break;
      case 2:
        title = 'UTB Codebase';
        break;
      case 3:
        title = 'My Projects';
        break;
      case 4:
        title = 'Profile';
        break;
      default:
        title = 'UTB Codebase';
    }

    return AppBar(
      leading: SizedBox(
        width: 50.w,
        child: Image.asset(
          'lib/asset/logo.png',
          alignment: Alignment.center,
        ),
      ),
      title: Text(title),
      actions: _buildAppBarActions(context),
    );
  }

  List<Widget> _buildAppBarActions(BuildContext context) {
    if (_selectedIndex == 1) {
      // Codebase tab
      return [
        IconButton(
          icon: Icon(Icons.add, size: 24.sp),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const RepositoryPage()),
            );
          },
        ),
      ];
    } else if (_selectedIndex == 4 && !kIsWeb) {
      // Profile tab (only on mobile)
      return [
        Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
      ];
    }
    return const [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      drawer: Drawer(
        width: MediaQuery.of(context).size.width * 0.75,
        child: const SettingsContent(),
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        elevation: 0,
        unselectedItemColor: Colors.black,
        selectedItemColor: const Color.fromARGB(221, 193, 5, 33),
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.apps), label: 'App Store'),
          BottomNavigationBarItem(icon: Icon(Icons.storage), label: 'Codebase'),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Homepage'),
          BottomNavigationBarItem(
              icon: Icon(Icons.install_mobile), label: 'My Apps'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}
