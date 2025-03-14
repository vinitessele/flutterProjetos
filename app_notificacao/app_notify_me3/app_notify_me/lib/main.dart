import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'sendPushNotification.dart'; 
import 'sendRealDataBase.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyBl5siS4WXhcFgw5Vana_ZSmCqc_1kB1iU",
      appId: "1:131384577034:android:67ea2937c3a7fef71fa3f3",
      messagingSenderId: "131384577034",
      projectId: "push-5b79c",
    ),
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(debugShowCheckedModeBanner: false, home: HomeScreen());
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  @override
  void initState() {
    super.initState();
    _requestPermission();
    _setupFirebaseMessagingListener();
  }

  Future<void> _requestPermission() async {
    NotificationSettings settings =
        await _firebaseMessaging.requestPermission();
    print('Permissões concedidas: ${settings.authorizationStatus}');
  }

  void _setupFirebaseMessagingListener() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📩 Notificação recebida: ${message.notification?.title}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Notificação: ${message.notification?.body}")),
        );
      }
    });
  }

  void _openRemoteNotificationScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SendPushNotificationScreen()),
    );
  }

    void _openRealTimeDatabaseScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SendRealDataBaseScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Firebase Notifications')),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text(
                'Menu',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: Icon(Icons.home),
              title: Text('Home'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.send),
              title: Text('Envia Push'),
              onTap: () {
                Navigator.pop(context);
                _openRemoteNotificationScreen();
              },
            ),
                        ListTile(
              leading: Icon(Icons.send),
              title: Text('Envia e retorna dados RealtimeDataBase'),
              onTap: () {
                Navigator.pop(context);
                _openRealTimeDatabaseScreen();
              },
            ),
          ],
        ),
      ),
      body: Center(child: Text('Aguardando notificações...')),
    );
  }
}
