import 'package:flutter/material.dart';
import 'package:capstone_project/db_helper/firebase_options.dart';
import 'package:capstone_project/screen/login.dart';
import 'package:capstone_project/screen/homepage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:capstone_project/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("Firebase initialized successfully");
  } catch (e) {
    print("Failed to initialize Firebase: $e");
  }
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Biosentinel',
      theme: darkTheme(),
      initialRoute: '/login', // หน้าเริ่มต้น
      routes: {
        '/login': (context) => LoginPage(),
        '/home': (context) => HomePage(),
      },
    );
  }
}
