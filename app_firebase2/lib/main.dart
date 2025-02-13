import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  String? _versao;
  static const String _versaoApp = '1.1.0';
  final Uri _url = Uri.parse('https://1drv.ms/f/c/26724769b88ecd95/EgBlSjPLk6xIvKN4dZOjBysB4vI0u-I2Det0HlbWCpvp6Q?e=Tsksvm');


  @override
  void initState() {
    super.initState();
    _getVersao();
  }

  Future<void> _getVersao() async {
    DatabaseEvent event = await _database.child('versao').once();
    setState(() {
      _versao = event.snapshot.value.toString();
    });
  }

  // Função para abrir o link do Google Drive
Future<void> _baixarAPK() async {
  try {

    if (await canLaunchUrl(_url)) {
      await launchUrl(
        _url,
        mode: LaunchMode.externalApplication, // Abre no navegador padrão
      );
    } else {
      throw 'Não foi possível abrir o link';
    }
  } catch (e) {
    print('---> Erro ao abrir o link: $e');
  }
}

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text("Firebase Conectado!")),
        body: Column(
          children: [
            Center(
              child: _versao == null
                  ? CircularProgressIndicator()
                  : Text("Versão: $_versao"),
            ),
            Center(
              child: Text("Versão App: $_versaoApp"),
            ),
            if (_versao != null && _versao != _versaoApp)
              ElevatedButton(
                onPressed: _baixarAPK,
                child: Text("Baixar APK da versão mais recente"),
              )
          ],
        ),
      ),
    );
  }
}
