import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_init;

// Função que lida com mensagens em background
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Recebendo mensagem em background: ${message.messageId}");
}

// Canal de notificação para Android
const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel',
  'Notificações Importantes',
  description: 'Canal usado para notificações importantes',
  importance: Importance.high,
);

void main() async {
  // Garantir que Flutter esteja inicializado
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar Firebase
  await Firebase.initializeApp();
  
  // Definir manipulador de mensagens em background
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  // Inicializar plugin de notificações locais
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = 
      FlutterLocalNotificationsPlugin();
      
  // Criar canal de notificação no Android
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
      
  // Definir configurações do FCM para Android
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );
  
  // Inicializar dados de timezone
  tz_init.initializeTimeZones();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Agendador de Notificações',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
      ),
      home: const NotificationSchedulerScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class NotificationSchedulerScreen extends StatefulWidget {
  const NotificationSchedulerScreen({Key? key}) : super(key: key);

  @override
  State<NotificationSchedulerScreen> createState() => _NotificationSchedulerScreenState();
}

class _NotificationSchedulerScreenState extends State<NotificationSchedulerScreen> {
  // Controladores para campos de texto
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  
  // Data e hora selecionadas
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  
  // Instâncias para Firebase e notificações
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  // Token do dispositivo
  String? _deviceToken;
  
  // Inicialização
  @override
  void initState() {
    super.initState();
    _initNotifications();
    _registerDevice();
  }
  
  // Limpeza ao fechar
  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }
  
  // Inicializar configurações de notificações
  Future<void> _initNotifications() async {
    // Configuração para Android
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
        
    // Configurações de inicialização
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );
    
    // Inicializar plugin de notificações locais
    await _localNotifications.initialize(
      initializationSettings,
      onSelectNotification: (String? payload) async {
        if (payload != null) {
          debugPrint('Payload da notificação: $payload');
          // Aqui você pode navegar para uma tela específica quando a notificação for clicada
        }
      },
    );
    
    // Configurar handler para mensagens recebidas em foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Recebida mensagem no foreground!');
      
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;
      
      // Se a mensagem for para Android, mostrar notificação local
      if (notification != null && android != null) {
        _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              channelDescription: channel.description,
              icon: 'launch_background',
            ),
          ),
        );
      }
    });
    
    // Configurar ação quando notificação é clicada e o app está em background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Uma notificação foi clicada!');
      // Aqui você pode navegar para uma tela específica
    });
  }
  
  // Registrar dispositivo no Firestore
  Future<void> _registerDevice() async {
    // Solicitar permissão para notificações
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    
    print('Status de autorização: ${settings.authorizationStatus}');
    
    // Se permissão concedida, obter token
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      _deviceToken = await _messaging.getToken();
      print('Token FCM: $_deviceToken');
      
      // Salvar token no Firestore
      if (_deviceToken != null) {
        await FirebaseFirestore.instance
            .collection('devices')
            .doc(_deviceToken)
            .set({
              'token': _deviceToken,
              'platform': 'android',
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
      }
    }
  }
  
  // Mostrar seletor de data
  Future<void> _selectDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Selecione a data',
      cancelText: 'CANCELAR',
      confirmText: 'OK',
    );
    
    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }
  
  // Mostrar seletor de hora
  Future<void> _selectTime() async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      helpText: 'Selecione o horário',
      cancelText: 'CANCELAR',
      confirmText: 'OK',
    );
    
    if (pickedTime != null && pickedTime != _selectedTime) {
      setState(() {
        _selectedTime = pickedTime;
      });
    }
  }
  
  // Agendar notificação
  Future<void> _scheduleNotification() async {
    // Validar campos
    if (_titleController.text.isEmpty || _bodyController.text.isEmpty) {
      _showSnackBar('Preencha o título e a mensagem da notificação');
      return;
    }
    
    // Combinar data e hora selecionadas
    final DateTime scheduledDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
    
    // Verificar se a data está no futuro
    if (scheduledDateTime.isBefore(DateTime.now())) {
      _showSnackBar('Selecione uma data e hora no futuro');
      return;
    }
    
    try {
      // Salvar no Firestore
      await FirebaseFirestore.instance.collection('notifications').add({
        'title': _titleController.text,
        'body': _bodyController.text,
        'scheduledFor': Timestamp.fromDate(scheduledDateTime),
        'status': 'scheduled',
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': _deviceToken,
      });
      
      // Agendar localmente como fallback
      await _scheduleLocalNotification(
        _titleController.text,
        _bodyController.text,
        scheduledDateTime,
      );
      
      // Limpar formulário
      _titleController.clear();
      _bodyController.clear();
      
      _showSnackBar('Notificação agendada com sucesso');
    } catch (e) {
      _showSnackBar('Erro ao agendar: $e');
      print('Erro ao agendar notificação: $e');
    }
  }
  
  // Agendar notificação local (fallback)
  Future<void> _scheduleLocalNotification(
    String title,
    String body,
    DateTime scheduledDateTime,
  ) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'scheduled_channel',
      'Notificações Agendadas',
      channelDescription: 'Canal para notificações agendadas',
      importance: Importance.max,
      priority: Priority.high,
    );
    
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    
    await _localNotifications.zonedSchedule(
      title.hashCode,
      title,
      body,
      tz.TZDateTime.from(scheduledDateTime, tz.local),
      platformChannelSpecifics,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
  
  // Mostrar mensagem ao usuário
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agendador de Notificações'),
        elevation: 2,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Formulário
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Título da notificação
                      TextField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Título da Notificação',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.title),
                        ),
                        maxLength: 50,
                      ),
                      const SizedBox(height: 16),
                      
                      // Mensagem da notificação
                      TextField(
                        controller: _bodyController,
                        decoration: const InputDecoration(
                          labelText: 'Mensagem da Notificação',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.message),
                          alignLabelWithHint: true,
                        ),
                        maxLines: 3,
                        maxLength: 200,
                      ),
                      const SizedBox(height: 16),
                      
                      // Seleção de data e hora
                      const Text(
                        'Quando enviar a notificação:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Botões de data e hora
                      Row(
                        children: [
                          // Botão de data
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _selectDate,
                              icon: const Icon(Icons.calendar_today),
                              label: Text(
                                '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          
                          // Botão de hora
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _selectTime,
                              icon: const Icon(Icons.access_time),
                              label: Text(
                                '${_selectedTime.hour}:${_selectedTime.minute.toString().padLeft(2, '0')}',
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // Botão de agendamento
                      ElevatedButton.icon(
                        onPressed: _scheduleNotification,
                        icon: const Icon(Icons.notifications_active),
                        label: const Text('AGENDAR NOTIFICAÇÃO'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Título da lista de notificações agendadas
                      const Text(
                        'Notificações Agendadas:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
              
              // Lista de notificações agendadas
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('notifications')
                      .orderBy('scheduledFor')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Center(
                        child: Text('Erro ao carregar notificações'),
                      );
                    }
                    
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }
                    
                    final notifications = snapshot.data!.docs;
                    
                    if (notifications.isEmpty) {
                      return const Center(
                        child: Text('Nenhuma notificação agendada'),
                      );
                    }
                    
                    return ListView.builder(
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        final notification = notifications[index];
                        final data = notification.data() as Map<String, dynamic>;
                        final scheduledFor = (data['scheduledFor'] as Timestamp).toDate();
                        final status = data['status'] as String;
                        
                        // Cor baseada no status
                        Color statusColor;
                        if (status == 'sent') {
                          statusColor = Colors.green;
                        } else if (scheduledFor.isBefore(DateTime.now())) {
                          statusColor = Colors.orange;
                        } else {
                          statusColor = Colors.blue;
                        }
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(
                              data['title'],
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(data['body']),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${scheduledFor.day}/${scheduledFor.month} ${scheduledFor.hour}:${scheduledFor.minute.toString().padLeft(2, '0')}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: statusColor,
                                  ),
                                ),
                                Text(
                                  status == 'sent' ? 'Enviada' : 'Agendada',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: statusColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}