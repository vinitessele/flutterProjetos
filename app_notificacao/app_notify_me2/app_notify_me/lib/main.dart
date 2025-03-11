import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyAu1zFpSBRSzCR8WTEoB2jJ5B7QKIn-DVo",
      appId: "1:32059787177:android:16e0e248b7d834a0ffe6b8",
      messagingSenderId: "32059787177",
      projectId: "pushnotification2-3d423",
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
