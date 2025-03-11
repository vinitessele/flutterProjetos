import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';

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
    return MaterialApp(
      title: 'Notify Me',
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  String _message = '';

  _registerOnFirebase() {
    // Subscribing to a topic
    _firebaseMessaging.subscribeToTopic('all');
    
    // Get token
    _firebaseMessaging.getToken().then((token) => print("Token: $token"));
  }

  @override
  void initState() {
    super.initState();
    _registerOnFirebase();
    
    // Listen for foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Received message: ${message.notification?.body}');
      setState(() {
        _message = message.notification?.body ?? 'No message body';
      });
    });

    // Listen for messages when the app is opened from a notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Notification clicked! ${message.notification?.body}');
      setState(() {
        _message = message.notification?.body ?? 'No message body';
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Push Notifications Test'),
      ),
      body: Container(
        child: Center(
          child: Text("Message: $_message"),
        ),
      ),
    );
  }
}
