// ignore_for_file: prefer_const_constructors

import '/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'core/crudModel/project_crud.dart';
import 'core/crudModel/repo_crud.dart';
import 'core/crudModel/user_crud.dart';
import 'core/crudModel/comment_crud.dart';
import 'core/models/user.dart'; 
import 'screens/apps/app_store.dart';
import 'screens/myProjects/my_projects.dart';
import 'screens/authentication/login.dart';
import 'screens/codebaseStorage/repository_create.dart';
import 'screens/codebaseStorage/repository_list.dart';
import 'screens/homepage.dart';
import 'screens/userProfile/profile.dart';
import 'screens/userProfile/settings.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CRUDUser()),
        ChangeNotifierProvider(create: (_) => CRUDProject()),
        ChangeNotifierProvider(create: (_) => CRUDRepo()),
        ChangeNotifierProvider(create: (_) => CRUDComment()),
      ],
      child: ScreenUtilInit(
        designSize: const Size(1920, 1080),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (_, child) => MaterialApp(
          title: 'UTB Codebase',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.red,
              brightness: Brightness.light,
            ),
            useMaterial3: true,
            visualDensity: VisualDensity.adaptivePlatformDensity,
          ),
          debugShowCheckedModeBanner: false,
          home: const AuthWrapper(),
        ),
        child: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User?>(
      future: Provider.of<CRUDUser>(context, listen: false).getCurrentUser(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasData && snapshot.data != null) {
          return const MyMain();
        } else {
          return LoginPage();
        }
      },
    );
  }
}

class MyMain extends StatefulWidget {
  const MyMain({super.key});

  @override
  State<MyMain> createState() => _MyMainState();
}

class _MyMainState extends State<MyMain> {
  int _selectedIndex = 2;

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
      body: kIsWeb ? _buildWebLayout() : _buildMobileLayout(),
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

  Widget _buildWebLayout() {
    return ScreenUtilInit(
      designSize: const Size(1920, 1080),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, child) => Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            labelType: NavigationRailLabelType.selected,
            destinations: const <NavigationRailDestination>[
              NavigationRailDestination(
                icon: Icon(Icons.apps),
                selectedIcon: Icon(Icons.apps),
                label: Text('App Store'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.storage),
                selectedIcon: Icon(Icons.storage),
                label: Text('Codebase'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.home),
                selectedIcon: Icon(Icons.home),
                label: Text('Homepage'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.install_mobile),
                selectedIcon: Icon(Icons.install_mobile),
                label: Text('My Apps'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.person),
                selectedIcon: Icon(Icons.person),
                label: Text('Profile'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: const [
                AppStorePage(),
                RepositoryList(),
                HomePage(),
                MyProjects(),
                ProfilePage(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return IndexedStack(
      index: _selectedIndex,
      children: const [
        AppStorePage(),
        RepositoryList(),
        HomePage(),
        MyProjects(),
        ProfilePage(),
      ],
    );
  }
}
