import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'core/auth/auth_provider.dart';
import 'core/crudModel/comment_crud.dart';
import 'core/crudModel/project_crud.dart';
import 'core/crudModel/repo_crud.dart';
import 'core/crudModel/user_crud.dart';
import 'firebase_options.dart';
import 'screens/authentication/auth_wrapper.dart';

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
        // Auth provider
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(),
        ),

        // CRUD providers
        ChangeNotifierProvider<CRUDUser>(
          create: (_) => CRUDUser(),
        ),
        ChangeNotifierProvider<CRUDProject>(
          create: (_) => CRUDProject(),
        ),
        ChangeNotifierProvider<CRUDRepo>(
          create: (_) => CRUDRepo(),
        ),
        ChangeNotifierProvider<CRUDComment>(
          create: (_) => CRUDComment(),
        ),
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
      ),
    );
  }
}
