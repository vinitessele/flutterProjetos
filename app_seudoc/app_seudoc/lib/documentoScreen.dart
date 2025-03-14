import 'package:app_seudoc/loginScreen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class DocumentoScreen extends StatefulWidget {
  const DocumentoScreen({super.key});

  @override
  State<DocumentoScreen> createState() => _DocumentoScreenState();
}

class _DocumentoScreenState extends State<DocumentoScreen> {
  String _userDocument = '';
  List<Document> _documents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    _userDocument = prefs.getString('userDocument') ?? '';
    
    if (_userDocument.isEmpty) {
      // Redireciona para login se não houver documento salvo
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
      return;
    }
    
    await _fetchDocuments();
  }

  Future<void> _fetchDocuments() async {
    // Simula busca de documentos de um serviço
    await Future.delayed(Duration(seconds: 1));
    
    // Documentos mockados para teste
    List<Document> allDocuments = [
      Document(
        id: '1',
        name: '12345678900_contrato.pdf',
        downloadUrl: 'https://drive.google.com/file/d/abc123/view?usp=sharing',
        date: '10/03/2025',
        size: '2.4 MB',
        type: 'PDF',
      ),
      Document(
        id: '2',
        name: '12345678900_recibo.pdf',
        downloadUrl: 'https://drive.google.com/file/d/def456/view?usp=sharing',
        date: '08/03/2025',
        size: '1.1 MB',
        type: 'PDF',
      ),
      Document(
        id: '3',
        name: '11222333000199_contrato.pdf',
        downloadUrl: 'https://drive.google.com/file/d/ghi789/view?usp=sharing',
        date: '05/03/2025',
        size: '3.7 MB',
        type: 'PDF',
      ),
      Document(
        id: '4',
        name: '98765432100_extrato.pdf',
        downloadUrl: 'https://drive.google.com/file/d/jkl012/view?usp=sharing',
        date: '28/02/2025',
        size: '0.8 MB',
        type: 'PDF',
      ),
    ];
    
    // Filtra documentos que começam com o CPF/CNPJ do usuário
    _documents = allDocuments.where((doc) => 
      doc.name.startsWith('$_userDocument')
    ).toList();
    
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userDocument');
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  Future<void> _downloadDocument(Document document) async {
    // Abre a URL em um navegador para baixar o arquivo
    if (await canLaunchUrl(Uri.parse(document.downloadUrl))) {
      await launchUrl(Uri.parse(document.downloadUrl));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Não foi possível abrir o link'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  String _formatDocumentName(String name) {
    if (name.startsWith(_userDocument)) {
      return name.substring(_userDocument.length + 1); // +1 para remover o underscore
    }
    return name;
  }

  Widget _getFileIcon(String type) {
    IconData icon;
    Color color;
    
    switch (type.toLowerCase()) {
      case 'pdf':
        icon = Icons.picture_as_pdf;
        color = Colors.red;
        break;
      case 'doc':
      case 'docx':
        icon = Icons.description;
        color = Colors.blue;
        break;
      case 'xls':
      case 'xlsx':
        icon = Icons.table_chart;
        color = Colors.green;
        break;
      case 'jpg':
      case 'jpeg':
      case 'png':
        icon = Icons.image;
        color = Colors.purple;
        break;
      default:
        icon = Icons.insert_drive_file;
        color = Colors.grey;
    }
    
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        color: color,
        size: 28,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'SeuDoc',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Color(0xFF2A74E0),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: _logout,
            tooltip: 'Sair',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.only(left: 20, right: 20, bottom: 20),
            decoration: BoxDecoration(
              color: Color(0xFF2A74E0),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Meus Documentos',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Documentos disponíveis para download',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2A74E0)),
                    ),
                  )
                : _documents.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.folder_open,
                              size: 80,
                              color: Colors.grey.shade400,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Nenhum documento encontrado',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.all(16),
                        itemCount: _documents.length,
                        itemBuilder: (context, index) {
                          return Card(
                            margin: EdgeInsets.only(bottom: 16),
                            child: InkWell(
                              onTap: () => _downloadDocument(_documents[index]),
                              borderRadius: BorderRadius.circular(16),
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    _getFileIcon(_documents[index].type),
                                    SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _formatDocumentName(_documents[index].name),
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Text(
                                                _documents[index].date,
                                                style: TextStyle(
                                                  color: Colors.grey.shade600,
                                                  fontSize: 13,
                                                ),
                                              ),
                                              SizedBox(width: 8),
                                              Container(
                                                width: 4,
                                                height: 4,
                                                decoration: BoxDecoration(
                                                  color: Colors.grey.shade400,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              SizedBox(width: 8),
                                              Text(
                                                _documents[index].size,
                                                style: TextStyle(
                                                  color: Colors.grey.shade600,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.download,
                                        color: Color(0xFF2A74E0),
                                      ),
                                      onPressed: () => _downloadDocument(_documents[index]),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class Document {
  final String id;
  final String name;
  final String downloadUrl;
  final String date;
  final String size;
  final String type;

  Document({
    required this.id,
    required this.name,
    required this.downloadUrl,
    required this.date,
    required this.size,
    required this.type,
  });
}