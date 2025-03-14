import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SendPushNotificationScreen extends StatefulWidget {
  @override
  _SendPushNotificationScreenState createState() =>
      _SendPushNotificationScreenState();
}

class _SendPushNotificationScreenState
    extends State<SendPushNotificationScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();

  Future<void> _sendNotification() async {
    const String projectId = "push-5b79c"; // Substitua pelo seu Project ID
    const String fcmUrl =
        "https://fcm.googleapis.com/v1/projects/$projectId/messages:send"; 
    const String accessToken = "ya29.c.c0ASRK0Ga5YVrWH8SQ1U5xuWAPueZANi7QBG4YAQ32QQK9f0VYJqNIvSc2yBeI5pYPkliFF3Jbl79yrr958u0PXrBWlq9PXNOF-tNu8KiqQsRnAVzUqTChzDPk_9TzPmYhSzAWqUCL-SOFnskH5_4jrJA-9HkIJaLOo_vt253GIWZLl0CzyxfjuObAesQ2UV4sO0unhDTUH0nCjzSJ6bgmPGHD0ZEdbaEXrJxuktfePQ7_-Dw_KBCSCCfp7YJ2peZHjEnv8bTjVvsUsk7w3kvSPT8fHKTrmkGM0HgyB2fR8dazRa1AEoKbdtaUCbY5n10-2nPpdoIiUefEPzNOdksN1EGZck2WVByxBWCSmq69fzAadEct_Kz6Hj6qN385COYyv4xo4gV47eYupryF-oxySBy2UU0kpoVl5y--44_tVd_opjdebBgc0hQmd_mS3tUIoqJybYl557ycmc_7a3kMhrZFV4o0vMb09Q3aoSr6jb9bdOpkBiS6oSl3FnBVy7ki75p5YnW63XtWIy8o-XvR-lfwYOMl3-sS9WMiqlhhM-k75UJzoBVhSr0wc7wyd_cU6iuhzc8j4dsqggWwe2Yme_cWel1pixsB-kB34nhzBc8xh9ukozWBifSfmRj3610n2nMmz1uh8YpZoq8UxwQ5IY46deJl-0Ubu10-mk-UzFvpr9igpzq423d6hVg_dzB0X8qvfbZ33bkB4yaQ7XgyqWBsQ8pjrWzoZna69uXvvydhb_V-QrZfMpir2p10U2w3as73j5V-0ncJmqMfZ4-rph7Jz7R2_zlx5VUrWgrujplo84rXjcx0QF1eaz0auJf8YIuwb8yX1jj3R7uIWywz6hZZm_IgkMqj7oR0Svqesl4l8ad1jsMylac_Uc4zbQhsy87jVscdmqlMd1e9a5JnVFcBi5m3bOxkzlMZZ8ydnt6ufY57rhuu-msykk2pwm5r_VgWmgbpUO5_inz9QIt8a8SBJZpRXl18y0lM3izSn5R6tmtbSsWMaWw"; // Substitua pelo Access Token gerado

    String title = _titleController.text;
    String body = _bodyController.text;
    int delayInSeconds = int.tryParse(_timeController.text) ?? 0; // Atraso

    Future.delayed(Duration(seconds: delayInSeconds), () async {
      try {
        var headers = {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken', // O token de acesso v1
        };

        var bodyData = jsonEncode({
          "message": {
            "topic": "all", // Envia para todos os dispositivos inscritos no tópico "all"
            "notification": {
              "title": title,
              "body": body,
            },
          },
        });

        var response =
            await http.post(Uri.parse(fcmUrl), headers: headers, body: bodyData);

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Notificação enviada com sucesso!")),
          );
          print("Resposta do FCM: ${response.body}");
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Erro ao enviar notificação: ${response.body}")),
          );
          print("Erro: ${response.statusCode} | ${response.body}");
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao enviar notificação: $e")),
        );
        print("Exceção: $e");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Enviar Notificação")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(labelText: "Título"),
            ),
            TextField(
              controller: _bodyController,
              decoration: InputDecoration(labelText: "Mensagem"),
            ),
            TextField(
              controller: _timeController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: "Atraso (segundos)"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _sendNotification,
              child: Text("Enviar Notificação"),
            ),
          ],
        ),
      ),
    );
  }
}
