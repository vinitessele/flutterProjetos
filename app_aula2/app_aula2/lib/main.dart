import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

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

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  String? _versao;

  @override
  void initState() {
    super.initState();
    _getVersao();
  }

  // Função para pegar a versão do Firebase
  Future<void> _getVersao() async {
    final event = await _database.child('versao').once();
    setState(() {
      _versao = event.snapshot.value?.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text("Versão do Firebase")),
        body: Center(
          child: _versao == null
              ? CircularProgressIndicator()
              : Text("Versão no Firebase: $_versao"),
        ),
      ),
    );
  }
}
