import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  } else {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Clientes Offline',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomePage(),
    );
  }
}

class Cliente {
  final int id;
  final String uuid;
  final String nome;
  final String telefone;
  final String createdAt;
  final String updatedAt;
  final int isDeleted;

  Cliente({
    required this.id,
    required this.uuid,
    required this.nome,
    required this.telefone,
    required this.createdAt,
    required this.updatedAt,
    required this.isDeleted,
  });

  factory Cliente.fromMap(Map<String, dynamic> map) => Cliente(
    id: map['id'],
    uuid: map['uuid'],
    nome: map['nome'],
    telefone: map['telefone'],
    createdAt: map['created_at'],
    updatedAt: map['updated_at'],
    isDeleted: map['is_deleted'],
  );
}

class DatabaseHelper {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  static Future<Database> _initDb() async {
    String path;

    if (kIsWeb) {
      // No Web, usamos um nome simples (salvo direto na raiz do IndexedDB)
      path = 'clientes_web.db';
    } else {
      // No Android/iOS/Desktop, usamos o caminho padrão
      final dbPath = await databaseFactory.getDatabasesPath();
      path = p.join(dbPath, 'clientes.db');
    }

    return await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS clientes (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              uuid TEXT UNIQUE,
              nome TEXT NOT NULL,
              telefone TEXT NOT NULL,
              created_at TEXT,
              updated_at TEXT,
              is_deleted INTEGER DEFAULT 0
            )
          ''');

          // Clientes de exemplo
          await db.insert('clientes', {
            "uuid": const Uuid().v4(),
            "nome": "João Silva",
            "telefone": "(11) 98765-4321",
            "created_at": DateTime.now().toString(),
            "updated_at": DateTime.now().toString(),
            "is_deleted": 0,
          });

          await db.insert('clientes', {
            "uuid": const Uuid().v4(),
            "nome": "Maria Oliveira",
            "telefone": "(21) 99876-5432",
            "created_at": DateTime.now().toString(),
            "updated_at": DateTime.now().toString(),
            "is_deleted": 0,
          });

          await db.insert('clientes', {
            "uuid": const Uuid().v4(),
            "nome": "Carlos Santos",
            "telefone": "(31) 97654-3210",
            "created_at": DateTime.now().toString(),
            "updated_at": DateTime.now().toString(),
            "is_deleted": 0,
          });
        },
      ),
    );
  }

  static Future<List<Cliente>> getClientes() async {
    final db = await database;
    final res = await db.query('clientes', where: 'is_deleted = 0');
    return res.map((e) => Cliente.fromMap(e)).toList();
  }

  static Future<void> insertCliente(Map<String, dynamic> data) async {
    final db = await database;
    final now = DateTime.now().toString();
    await db.insert('clientes', {
      'uuid': const Uuid().v4(),
      'nome': data['nome'],
      'telefone': data['telefone'],
      'created_at': now,
      'updated_at': now,
      'is_deleted': 0,
    });
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Cliente> clientes = [];

  @override
  void initState() {
    super.initState();
    _carregarClientes();
  }

  void _carregarClientes() async {
    final data = await DatabaseHelper.getClientes();
    setState(() => clientes = data);
  }

  void _mostrarDialogoAdicionarCliente() {
    final nomeController = TextEditingController();
    final telefoneController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Novo Cliente'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nomeController,
                  decoration: const InputDecoration(labelText: 'Nome'),
                ),
                TextField(
                  controller: telefoneController,
                  decoration: const InputDecoration(labelText: 'Telefone'),
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final nome = nomeController.text.trim();
                  final telefone = telefoneController.text.trim();
                  if (nome.isNotEmpty && telefone.isNotEmpty) {
                    await DatabaseHelper.insertCliente({
                      'nome': nome,
                      'telefone': telefone,
                    });
                    Navigator.pop(context);
                    _carregarClientes();
                  }
                  nomeController.dispose();
                  telefoneController.dispose();
                },
                child: const Text('Salvar'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lista de Clientes')),
      body: ListView.builder(
        itemCount: clientes.length,
        itemBuilder: (context, index) {
          final cliente = clientes[index];
          return ListTile(
            title: Text(cliente.nome),
            subtitle: Text(cliente.telefone),
            trailing: Text(cliente.createdAt.split(' ')[0]), // Data simples
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _mostrarDialogoAdicionarCliente,
        child: const Icon(Icons.add),
      ),
    );
  }
}
