import 'package:app_seudoc/documentoScreen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _documentController = TextEditingController();
  final _passwordController = TextEditingController();
  String _errorMessage = '';
  bool _isLoading = false;
  bool _obscurePassword = true;
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;

  // Lista fixa de CPF/CNPJ válidos para teste com senhas
  final Map<String, String> _validCredentials = {
    '12345678900': 'senha123', // CPF exemplo
    '11222333000199': 'senha123', // CNPJ exemplo
    '98765432100': 'senha123', // Outro CPF exemplo
  };

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1200),
    );
    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.0, 1.0, curve: Curves.easeOut),
      ),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _documentController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  String? _validateDocument(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor, insira o CPF ou CNPJ';
    }
    
    // Remove caracteres não numéricos
    String document = value.replaceAll(RegExp(r'[^\d]'), '');
    
    if ((document.length != 11) && (document.length != 14)) {
      return 'CPF deve ter 11 dígitos ou CNPJ deve ter 14 dígitos';
    }
    
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor, insira sua senha';
    }
    
    if (value.length < 6) {
      return 'A senha deve ter pelo menos 6 caracteres';
    }
    
    return null;
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      // Remove caracteres não numéricos
      String document = _documentController.text.replaceAll(RegExp(r'[^\d]'), '');
      String password = _passwordController.text;
      
      // Simula verificação de login
      await Future.delayed(Duration(seconds: 1));
      
      if (_validCredentials.containsKey(document) && 
          _validCredentials[document] == password) {
        // Salva o documento para uso posterior
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userDocument', document);
        
        // Navega para a tela de documentos
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => DocumentoScreen()),
        );
      } else {
        setState(() {
          _errorMessage = 'CPF/CNPJ ou senha inválidos.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeInAnimation,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.white, Colors.blue.shade50],
              ),
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: 40),
                      // Logo
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Color(0xFF2A74E0),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFF2A74E0).withOpacity(0.3),
                              blurRadius: 20,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            Icons.description,
                            size: 60,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(height: 24),
                      Text(
                        'SeuDoc',
                        style: GoogleFonts.poppins(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2A74E0),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Seus documentos, quando você precisar',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 40),
                      TextFormField(
                        controller: _documentController,
                        decoration: InputDecoration(
                          labelText: 'CPF/CNPJ',
                          hintText: 'Digite seu documento',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        keyboardType: TextInputType.number,
                        validator: _validateDocument,
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: 'Senha',
                          hintText: 'Digite sua senha',
                          prefixIcon: Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off : Icons.visibility,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        obscureText: _obscurePassword,
                        validator: _validatePassword,
                      ),
                      SizedBox(height: 16),
                      if (_errorMessage.isNotEmpty)
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline, color: Colors.red),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage,
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        ),
                      SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        child: _isLoading
                            ? SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  strokeWidth: 2.5,
                                ),
                              )
                            : Text(
                                'Entrar',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(double.infinity, 56),
                          elevation: 4,
                        ),
                      ),
                      SizedBox(height: 16),
                      TextButton(
                        onPressed: () {
                          // Implementação futura para recuperação de senha
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Funcionalidade de recuperação de senha em desenvolvimento'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        child: Text(
                          'Esqueceu sua senha?',
                          style: TextStyle(
                            color: Color(0xFF2A74E0),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}