import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // 🔥 এইটা add করো
import 'home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔥 Firebase initialize with options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

// 🌟 Root App
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase CRUD App',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: false,
      ),

      home: const HomeScreen(),
    );
  }
}