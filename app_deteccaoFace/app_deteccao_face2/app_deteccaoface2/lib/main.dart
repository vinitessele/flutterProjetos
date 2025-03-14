import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  runApp(FaceDetectionApp(cameras: cameras));
}

class FaceDetectionApp extends StatelessWidget {
  final List<CameraDescription> cameras;

  FaceDetectionApp({required this.cameras});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: FaceDetectionScreen(cameras: cameras),
    );
  }
}

class FaceDetectionScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  FaceDetectionScreen({required this.cameras});

  @override
  _FaceDetectionScreenState createState() => _FaceDetectionScreenState();
}

class _FaceDetectionScreenState extends State<FaceDetectionScreen> {
  late CameraController _cameraController;
  late FaceDetector _faceDetector;
  bool _isDetecting = false;
  List<Face> _faces = [];
  int _selectedCameraIndex = 0; // Índice da câmera atual
  bool _isCameraInitialized = false; // Flag para verificar se a câmera foi inicializada

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(enableContours: true, enableClassification: true),
    );
  }

  Future<void> _initializeCamera() async {
    // Verifica se a câmera já foi inicializada antes de tentar descartá-la
    if (_isCameraInitialized) {
      await _cameraController.dispose();
    }

    try {
      _cameraController = CameraController(
        widget.cameras[_selectedCameraIndex],
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await _cameraController.initialize();

      _isCameraInitialized = true; // Marca a câmera como inicializada

      if (mounted) {
        setState(() {});
        _startFaceDetection();
      }
    } catch (e) {
      print('Erro ao inicializar câmera: $e');
    }
  }

  void _toggleCamera() {
    setState(() {
      _selectedCameraIndex = (_selectedCameraIndex + 1) % widget.cameras.length;
    });
    _initializeCamera();
  }

  InputImage _inputImageFromCameraImage(CameraImage image) {
    final camera = widget.cameras[_selectedCameraIndex];
    final rotation = InputImageRotationValue.fromRawValue(camera.sensorOrientation) ??
        InputImageRotation.rotation0deg;

    final format = InputImageFormatValue.fromRawValue(image.format.raw) ??
        InputImageFormat.nv21;

    final inputImageData = InputImageMetadata(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      rotation: rotation,
      format: format,
      bytesPerRow: image.planes[0].bytesPerRow,
    );

    return InputImage.fromBytes(
      bytes: image.planes[0].bytes,
      metadata: inputImageData,
    );
  }

  void _startFaceDetection() {
    _cameraController.startImageStream((CameraImage image) async {
      if (_isDetecting) return;
      _isDetecting = true;

      try {
        final inputImage = _inputImageFromCameraImage(image);
        final faces = await _faceDetector.processImage(inputImage);

        print('Faces detectadas: ${faces.length}');

        if (mounted) {
          setState(() {
            _faces = faces;
          });
        }
      } catch (e) {
        print('Erro ao processar imagem: $e');
      } finally {
        _isDetecting = false;
      }
    });
  }

  @override
  void dispose() {
    if (_isCameraInitialized) {
      _cameraController.dispose();
    }
    _faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized || !_cameraController.value.isInitialized) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: Text('Detecção Facial em Tempo Real')),
      body: Stack(
        children: [
          CameraPreview(_cameraController),
          CustomPaint(
            painter: FacePainter(
              faces: _faces,
              imageSize: Size(
                _cameraController.value.previewSize!.height,
                _cameraController.value.previewSize!.width,
              ),
              viewSize: MediaQuery.of(context).size,
            ),
            size: Size.infinite,
          ),
          Positioned(
            top: 50,
            left: 20,
            child: Text(
              'Rostos detectados: ${_faces.length}',
              style: TextStyle(fontSize: 20, color: Colors.white, backgroundColor: Colors.black),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _toggleCamera,
        child: Icon(Icons.switch_camera),
      ),
    );
  }
}

class FacePainter extends CustomPainter {
  final List<Face> faces;
  final Size imageSize;
  final Size viewSize;

  FacePainter({
    required this.faces,
    required this.imageSize,
    required this.viewSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = Colors.green;

    for (var face in faces) {
      final double scaleX = viewSize.width / imageSize.height;
      final double scaleY = viewSize.height / imageSize.width;

      final Rect scaledRect = Rect.fromLTRB(
        face.boundingBox.left * scaleX,
        face.boundingBox.top * scaleY,
        face.boundingBox.right * scaleX,
        face.boundingBox.bottom * scaleY,
      );

      canvas.drawRect(scaledRect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant FacePainter oldDelegate) {
    return faces != oldDelegate.faces;
  }
}