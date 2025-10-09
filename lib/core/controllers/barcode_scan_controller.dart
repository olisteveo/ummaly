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

  /// We show AI as a distinct step → 4 total (cert, ingredients, analysis, AI).
  int loadingTotal = 4;

  /// Overlay texts
  String loadingTitle = 'Checking product…';
  String loadingSubtitle = 'Certification, ingredients (OFF → OCR), analysis';

  /// Optional short label shown under “Step n of m” (e.g., “Reading label…”)
  String? loadingPhaseLabel;

  Timer? _stepperTimer; // no longer used (kept for compatibility)

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

    // Init overlay with a neutral default
    loadingStep = 1;
    loadingTotal = 4; // may be overridden by onPhase or backend steps
    loadingTitle = 'Checking product…';
    loadingSubtitle = 'Certification, ingredients (OFF → OCR), analysis';
    loadingPhaseLabel = null; // will be set by onPhase
    // NOTE: we do NOT start the auto-stepper timer anymore.
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
        onPhase: (title, {String? subtitle, int? step, int? total}) {
          // Drive the overlay precisely from the service phases
          if (step != null) loadingStep = step;
          if (total != null) loadingTotal = total;
          loadingTitle = title;
          if (subtitle != null) loadingSubtitle = subtitle;

          // Show a concise phase label line (we can reuse the title)
          loadingPhaseLabel = title;

          isLoading = true; // ensure overlay visible during phases
          notifyListeners();
        },
      );

      if (product != null) {
        productData = product.toJson();

        // If backend provides analysis_steps, reflect the true total
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
      _stopOverlayStepper(); // no-op for safety (legacy)
      isLoading = false;
      loadingPhaseLabel = null; // hide extra label when overlay goes away
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
    loadingSubtitle = 'Certification, ingredients (OFF → OCR), analysis';
    loadingPhaseLabel = null;

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

  // Legacy stepper functions (kept for compatibility; no longer used)
  void _startOverlayStepper() {
    // Intentionally disabled: phases are now driven by the service via onPhase().
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
