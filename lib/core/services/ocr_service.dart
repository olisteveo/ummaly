import 'dart:async';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// On-device OCR (private & £0). Keeps the camera + OCR logic out of widgets.
class OcrService {
  final ImagePicker _picker = ImagePicker();
  final TextRecognizer _recognizer = TextRecognizer();

  /// Returns the recognized text from a freshly snapped photo, or null if cancelled/empty.
  Future<String?> captureAndRecognize() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.rear,
      imageQuality: 85,
    );
    if (photo == null) return null;

    final input = InputImage.fromFilePath(photo.path);
    final RecognizedText rt = await _recognizer.processImage(input);

    // Join blocks (better than raw lines for labels)
    final text = rt.blocks.map((b) => b.text).join(' ').replaceAll('\n', ' ').trim();
    return text.isEmpty ? null : text;
  }

  Future<void> dispose() async {
    await _recognizer.close();
  }
}
