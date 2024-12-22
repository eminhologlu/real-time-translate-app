import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';

class CameraPage extends StatefulWidget {
  final TranslateLanguage sourceLanguage;
  final TranslateLanguage targetLanguage;

  const CameraPage({
    super.key,
    required this.sourceLanguage,
    required this.targetLanguage,
  });

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  final int _cameraIndex = 0;
  bool isCameraInitialized = false;
  bool isCameraActive = false;
  bool isImageStreamPaused = false;
  Uint8List? lastCapturedFrame;
  bool isProcessingImage = false;
  late OnDeviceTranslator _onDeviceTranslator;
  FlashMode _currentFlashMode = FlashMode.off;
  bool isFlashOn = false;

  List<TextBlock> recognizedTexts = [];
  List<String> translatedTexts = [];

  final int minLengthForRecognition = 3;

  @override
  void initState() {
    super.initState();
    _onDeviceTranslator = OnDeviceTranslator(
      sourceLanguage: widget.sourceLanguage,
      targetLanguage: widget.targetLanguage,
    );
    _loadCameras();
  }

  Future<void> _loadCameras() async {
    _cameras = await availableCameras();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    if (_cameras != null && _cameras!.isNotEmpty) {
      _controller = CameraController(
        _cameras![_cameraIndex],
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );

      await _controller!.initialize();
      setState(() {
        isCameraInitialized = true;
        isCameraActive = true;
      });

      _controller!.startImageStream((CameraImage image) async {
        if (!isProcessingImage && !isImageStreamPaused) {
          _processCameraImage(image);
        }
      });
    }
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;

    return InputImage.fromBytes(
      bytes: image.planes.first.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: InputImageRotation.rotation0deg,
        format: format,
        bytesPerRow: image.planes.first.bytesPerRow,
      ),
    );
  }

  Map<String, String> translationCache = {}; // Cache for translations

  Future<void> _processCameraImage(CameraImage image) async {
    isProcessingImage = true;
    final inputImage = _inputImageFromCameraImage(image);
    if (inputImage != null) {
      await _recognizeText(inputImage);
    }
    isProcessingImage = false;
  }

  Future<void> _recognizeText(InputImage inputImage) async {
    final textRecognizer = TextRecognizer();
    final recognizedTextResult = await textRecognizer.processImage(inputImage);

    recognizedTexts.clear();
    translatedTexts.clear();

    for (TextBlock block in recognizedTextResult.blocks) {
      if (block.text.length >= minLengthForRecognition) {
        recognizedTexts.add(block);

        // Check if the text is already translated
        String translation;
        if (translationCache.containsKey(block.text)) {
          translation = translationCache[block.text]!;
        } else {
          translation = await _onDeviceTranslator.translateText(block.text);
          translationCache[block.text] = translation; // Cache the translation
        }
        translatedTexts.add(translation);
      }
    }

    print('Recognized texts: ${recognizedTexts.length}');
    print('Translated texts: ${translatedTexts.length}');

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _toggleFlash() async {
    if (_controller != null && isCameraActive) {
      setState(() {
        isFlashOn = !isFlashOn;
        _currentFlashMode = isFlashOn ? FlashMode.torch : FlashMode.off;
      });
      await _controller!.setFlashMode(_currentFlashMode);
    }
  }

  Future<void> _pauseStreamAndRecognize() async {
    if (_controller != null && isCameraActive) {
      await _controller!.stopImageStream();
      setState(() {
        isImageStreamPaused = true;
        isCameraActive = false;
      });

      final XFile lastFrame = await _controller!.takePicture();
      final bytes = await lastFrame.readAsBytes();
      setState(() {
        lastCapturedFrame = bytes;
      });
    }
  }

  Future<void> _resumeStream() async {
    if (_controller != null && !isCameraActive) {
      setState(() {
        recognizedTexts.clear();
        translatedTexts.clear();
        lastCapturedFrame = null;
        isCameraActive = true;
        isImageStreamPaused = false;
      });

      _controller!.startImageStream((CameraImage image) {
        if (!isProcessingImage && !isImageStreamPaused) {
          _processCameraImage(image);
        }
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _onDeviceTranslator.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return Scaffold(
      body: Stack(
        children: [
          // Kamera önizlemesi
          Positioned.fill(
            child: isCameraInitialized
                ? lastCapturedFrame != null
                    ? Image.memory(lastCapturedFrame!, fit: BoxFit.cover)
                    : CameraPreview(_controller!)
                : const Center(child: Text("Kamera kapalı. Açılıyor...")),
          ),
          // Sol üst köşeye manuel geri butonu yerleştiriyoruz
          Positioned(
            top: 30,
            left: 10,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
          // Tanınan ve çevrilen metinleri ekranda göstermek için katman
          ..._buildTextOverlays(),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed:
                isImageStreamPaused ? _resumeStream : _pauseStreamAndRecognize,
            child: Icon(
              isImageStreamPaused ? Icons.play_arrow : Icons.pause,
            ),
          ),
          SizedBox(height: width * 0.02),
          FloatingActionButton(
            onPressed: _toggleFlash,
            child: Icon(isFlashOn ? Icons.flash_on : Icons.flash_off),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTextOverlays() {
    List<Widget> overlays = [];

    if (_controller == null || !_controller!.value.isInitialized)
      return overlays;

    // Get camera image dimensions (raw resolution)
    final cameraSize = _controller!.value.previewSize;
    if (cameraSize == null) return overlays;

    // Get screen dimensions (display resolution)
    final screenSize = MediaQuery.of(context).size;
    final screenRatio = screenSize.width / screenSize.height;
    final cameraRatio = cameraSize.height / cameraSize.width;

    // Calculate scaling factors to map camera coordinates to screen coordinates
    double scaleX, scaleY;
    if (screenRatio > cameraRatio) {
      scaleX = screenSize.width / cameraSize.height;
      scaleY = screenSize.width / cameraSize.height;
    } else {
      scaleX = screenSize.height / cameraSize.width;
      scaleY = screenSize.height / cameraSize.width;
    }

    for (int i = 0; i < recognizedTexts.length; i++) {
      if (i < translatedTexts.length) {
        final recognizedText = recognizedTexts[i];
        final translatedText = translatedTexts[i];

        // Get the bounding box of the recognized text
        final boundingBox = recognizedText.boundingBox;
        final left = boundingBox.left * scaleX;
        final top = boundingBox.top * scaleY;

        // Create a transparent overlay for the translated text
        overlays.add(
          Positioned(
            left: left,
            top: top,
            child: Text(
              translatedText,
              style: const TextStyle(
                backgroundColor: Colors.black,
                color: Colors.white,
                fontSize: 9, // Adjust text size if needed
              ),
            ),
          ),
        );
      }
    }

    return overlays;
  }
}
