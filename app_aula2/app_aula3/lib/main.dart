import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyDGc92XURLehOsj7cWWRTjTNH3kv90D_tA",
      appId: "1:271581956403:android:8a2c35b053a9feda75d646",
      messagingSenderId: "271581956403",
      projectId: "conexao-firebase-add87",
      databaseURL: "https://conexao-firebase-add87-default-rtdb.firebaseio.com",
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
