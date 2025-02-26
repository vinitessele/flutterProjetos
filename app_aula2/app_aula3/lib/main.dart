import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyBXhVHxCsVU3lyN73JCzAOicnuXx2RLWF8",
      appId: "1:822896731754:android:f35cee6525c26152e90c13",
      messagingSenderId: "822896731754",
      projectId: "flutter-7cfc5",
      databaseURL: 'https://flutter-7cfc5-default-rtdb.firebaseio.com',
    ),
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text("Firebase Conectado!")),
        body: Center(child: Text("Firebase Funcionando 🚀")),
      ),
    );
  }
}
