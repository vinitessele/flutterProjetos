import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gravador de Frases',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const RecordingScreen(),
    );
  }
}

class Phrase {
  final String id;
  final String text;
  final String fileName;
  String? audioPath;
  bool isRecorded = false;
  bool isSaved = false;

  Phrase({required this.id, required this.text})
      : fileName = '${id}_${text.replaceAll(' ', '_')}.wav';
}

class RecordingScreen extends StatefulWidget {
  const RecordingScreen({Key? key}) : super(key: key);

  @override
  State<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen> {
  final _audioRecorder = AudioRecorder();
  final _audioPlayer = AudioPlayer();

  final List<Phrase> phrases = [
    Phrase(id: '001', text: 'Sim'),
    Phrase(id: '002', text: 'Não'),
    Phrase(id: '003', text: 'Obrigado(a)'),
    Phrase(id: '004', text: 'Por favor'),
    Phrase(id: '005', text: 'Olá'),
  ];

  int currentPhraseIndex = 0;
  bool isRecording = false;
  bool isPlaying = false;
  String statusMessage = '';
  bool isRecorderInitialized = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();

    _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        setState(() {
          isPlaying = false;
          statusMessage = 'Pronto para enviar';
        });
      }
    });
  }

  Future<void> _checkPermissions() async {
    try {
      final status = await Permission.microphone.request();
      if (status == PermissionStatus.granted) {
        setState(() {
          isRecorderInitialized = true;
          statusMessage = 'Pronto para gravar';
        });
      } else {
        setState(() => statusMessage = 'Permissão de microfone negada');
      }
    } catch (e) {
      setState(() => statusMessage = 'Erro ao verificar permissões: $e');
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> startRecording() async {
    if (!isRecorderInitialized) {
      setState(() => statusMessage = 'Gravador não inicializado');
      return;
    }

    try {
      if (await _audioRecorder.hasPermission()) {
        final directory = await getExternalStorageDirectory();
        final path = '${directory!.path}/Download/${phrases[currentPhraseIndex].fileName}';

        await _audioRecorder.start(
          RecordConfig(encoder: AudioEncoder.wav),
          path: path,
        );

        setState(() {
          isRecording = true;
          statusMessage = 'Gravando...';
        });
      } else {
        setState(() => statusMessage = 'Permissão de gravação negada');
      }
    } catch (e) {
      setState(() => statusMessage = 'Erro ao iniciar gravação: $e');
    }
  }

  Future<void> stopRecording() async {
    try {
      final path = await _audioRecorder.stop();

      if (path != null) {
        final current = phrases[currentPhraseIndex];
        current.audioPath = path;

        setState(() {
          current.isRecorded = true;
          isRecording = false;
          statusMessage = 'Gravação concluída!';
        });
      } else {
        setState(() {
          isRecording = false;
          statusMessage = 'Erro: caminho de gravação nulo';
        });
      }
    } catch (e) {
      setState(() {
        isRecording = false;
        statusMessage = 'Erro ao parar gravação: $e';
      });
    }
  }

  Future<void> playRecording() async {
    final current = phrases[currentPhraseIndex];
    final path = current.audioPath;

    if (path == null) {
      setState(() => statusMessage = 'Nenhuma gravação encontrada');
      return;
    }

    setState(() {
      isPlaying = true;
      statusMessage = 'Reproduzindo...';
    });

    try {
      await _audioPlayer.setFilePath(path);
      await _audioPlayer.play();
    } catch (e) {
      setState(() {
        isPlaying = false;
        statusMessage = 'Erro ao reproduzir: $e';
      });
    }
  }

  Future<void> saveRecording() async {
    final current = phrases[currentPhraseIndex];

    setState(() {
      current.isSaved = true;
      statusMessage = 'Gravação salva em Downloads!';
    });
  }

  Future<void> shareRecording() async {
    final current = phrases[currentPhraseIndex];
    final path = current.audioPath;

    if (path == null) {
      setState(() => statusMessage = 'Nenhuma gravação para compartilhar');
      return;
    }

    try {
      await Share.shareXFiles([XFile(path)], text: 'Áudio gravado: ${current.text}');
    } catch (e) {
      setState(() => statusMessage = 'Erro ao compartilhar: $e');
    }
  }

  Future<void> shareToWhatsApp() async {
    final current = phrases[currentPhraseIndex];
    final path = current.audioPath;

    if (path == null) {
      setState(() => statusMessage = 'Nenhuma gravação para compartilhar');
      return;
    }
    try {
      await Share.shareXFiles([XFile(path)], text: 'Áudio gravado: ${current.text}');
    } catch (e) {
      setState(() => statusMessage = 'Erro ao compartilhar: $e');
    }
  }

  void resetCurrentRecording() {
    final current = phrases[currentPhraseIndex];
    if (current.audioPath != null) {
      try {
        File(current.audioPath!).deleteSync();
      } catch (e) {
        debugPrint('Erro ao excluir arquivo: $e');
      }
      setState(() {
        current.audioPath = null;
        current.isRecorded = false;
        current.isSaved = false;
        statusMessage = 'Gravação apagada';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = phrases[currentPhraseIndex];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gravador de Frases'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: LinearProgressIndicator(
              value: (currentPhraseIndex + 1) / phrases.length,
              backgroundColor: Colors.grey[300],
              color: Colors.deepPurple,
            ),
          ),
          Text('Frase ${currentPhraseIndex + 1} de ${phrases.length}'),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: isRecording ? 80 : 100,
                  height: isRecording ? 80 : 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isRecording ? Colors.red : isPlaying ? Colors.blue : Colors.deepPurple,
                  ),
                  child: Icon(
                    isRecording ? Icons.mic : isPlaying ? Icons.volume_up : Icons.record_voice_over,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 20),
                Text(current.text, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Text(statusMessage, style: TextStyle(color: statusMessage.contains('Erro') ? Colors.red : Colors.green)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Wrap(
              spacing: 12,
              children: [
                ElevatedButton.icon(
                  onPressed: isRecorderInitialized ? (isRecording ? stopRecording : startRecording) : null,
                  icon: Icon(isRecording ? Icons.stop : Icons.mic),
                  label: Text(isRecording ? 'Parar' : 'Gravar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isRecording ? Colors.orange : Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
                if (current.isRecorded)
                  ElevatedButton.icon(
                    onPressed: playRecording,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Ouvir'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                  ),
                if (current.isRecorded && !current.isSaved)
                  ElevatedButton.icon(
                    onPressed: saveRecording,
                    icon: const Icon(Icons.save),
                    label: const Text('Salvar'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  ),
                if (current.isRecorded)
                  ElevatedButton.icon(
                    onPressed: shareRecording,
                    icon: const Icon(Icons.share),
                    label: const Text('Compartilhar'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                  ),
                if (current.isRecorded)
                  ElevatedButton.icon(
                    onPressed: shareToWhatsApp,
                    icon: const Icon(Icons.share),
                    label: const Text('WhatsApp'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  ),
                if (current.isRecorded)
                  IconButton(
                    onPressed: resetCurrentRecording,
                    icon: const Icon(Icons.delete, color: Colors.grey),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}