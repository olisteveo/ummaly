import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ummaly/core/services/scan_service.dart';

class BarcodeScanController extends ChangeNotifier {
  final ScanService _scanService = ScanService();
  final MobileScannerController cameraController = MobileScannerController();

  String? scannedCode;
  Map<String, dynamic>? productData;
  bool isLoading = false;
  bool isScannerPaused = false;
  String? errorMessage;

  /// Loading step state for the overlay (drives “Step n / total”)
  int loadingStep = 1;

  /// We now show AI as a distinct step → 4 total.
  /// If you later want to make this dynamic, you can set it from /api/status or
  /// from product.analysis_steps.length once you have it.
  int loadingTotal = 4;

  String loadingTitle = 'Checking product…';
  String loadingSubtitle = 'Certification registries, ingredients, and analysis';
  Timer? _stepperTimer;

  /// Track torch state manually since MobileScanner 7.x removed getter
  final ValueNotifier<TorchState> torchState = ValueNotifier(TorchState.off);

  /// Toggle torch and update state manually
  Future<void> toggleTorch() async {
    await cameraController.toggleTorch();
    torchState.value =
    (torchState.value == TorchState.on) ? TorchState.off : TorchState.on;
    notifyListeners();
  }

  /// Handle barcode detection
  Future<void> handleScan(String barcode) async {
    if (isScannerPaused) return;

    scannedCode = barcode;
    isScannerPaused = true;
    isLoading = true;
    errorMessage = null;
    productData = null;

    // Init overlay stepper
    loadingStep = 1;
    loadingTotal = 4; // show AI adjudication as step 4
    loadingTitle = 'Checking product…';
    loadingSubtitle = 'Certification registries, ingredients, and analysis';
    _startOverlayStepper();

    notifyListeners();

    // Stop camera immediately to avoid multiple detections of the same code
    try {
      await cameraController.stop();
    } catch (e) {
      if (kDebugMode) {
        print("Error stopping camera after detection: $e");
      }
    }

    final firebaseUid = FirebaseAuth.instance.currentUser?.uid;

    try {
      final product = await _scanService.scanProduct(
        barcode,
        firebaseUid: firebaseUid,
      );

      if (product != null) {
        productData = product.toJson();

        // If backend provides analysis_steps, we can reflect the true total
        final steps = (productData?['analysis_steps'] as List?) ?? const [];
        if (steps.isNotEmpty) {
          loadingTotal = steps.length; // typically 4 when AI is on
        }

        errorMessage = null;
      } else {
        productData = null;
        errorMessage = "Product not found or server error";
      }
    } catch (e) {
      productData = null;
      errorMessage = "Network error: $e";
    } finally {
      _stopOverlayStepper();
      isLoading = false;
      notifyListeners();
      // keep scanner paused so the ProductCard is visible; it resumes on "Scan again"
    }
  }

  /// Reset scanner state and allow scanning again
  void resetScan() {
    scannedCode = null;
    productData = null;
    errorMessage = null;
    isScannerPaused = false;

    // Reset overlay step state
    _stopOverlayStepper();
    loadingStep = 1;
    loadingTotal = 4;
    loadingTitle = 'Checking product…';
    loadingSubtitle = 'Certification registries, ingredients, and analysis';

    notifyListeners();

    // Restart camera with a short delay to fully reset analyzer
    Future(() async {
      await _restartCamera();
    });
  }

  /// Clear any cached products (useful on logout or session reset)
  void clearCache() {
    _scanService.clearCache();
    notifyListeners();
  }

  /// Stop the camera safely
  Future<void> _safeStop() async {
    try {
      await cameraController.stop();
    } catch (_) {
      // Ignore if already stopped
    }
  }

  /// Start the camera safely
  Future<void> _safeStart() async {
    try {
      await cameraController.start();
    } catch (e) {
      if (kDebugMode) {
        print("Error starting camera: $e");
      }
    }
  }

  /// Restart sequence to ensure MobileScanner analyzer resets cleanly
  Future<void> _restartCamera() async {
    await _safeStop();
    await Future.delayed(const Duration(milliseconds: 200));
    await _safeStart();
    // Note: resetAutoFocus() not available in current MobileScanner.
  }

  /// Optional: Stop the camera before disposing controller
  void stopCamera() {
    _safeStop();
  }

  void _startOverlayStepper() {
    _stepperTimer?.cancel();
    _stepperTimer = Timer.periodic(const Duration(milliseconds: 900), (t) {
      if (!isLoading) {
        t.cancel();
        return;
      }
      if (loadingStep < loadingTotal) {
        loadingStep++;
        // Keep user informed with step-specific subtitles
        if (loadingStep == 2) {
          loadingSubtitle = 'Fetching ingredients (ITS / OFF)…';
        } else if (loadingStep == 3) {
          loadingSubtitle = 'Analyzing (Rapid + Ummaly rules)…';
        } else if (loadingStep == 4) {
          loadingSubtitle = 'AI adjudication…';
        }
        notifyListeners();
      } else {
        t.cancel();
      }
    });
  }

  void _stopOverlayStepper() {
    _stepperTimer?.cancel();
    _stepperTimer = null;
  }

  @override
  void dispose() {
    _stopOverlayStepper();
    stopCamera();
    cameraController.dispose();
    torchState.dispose();
    super.dispose();
  }
}
