import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ummaly/core/models/product.dart';
import 'package:ummaly/core/services/scan_service.dart';
import 'package:ummaly/core/services/scan_quota_service.dart';

class BarcodeScanController extends ChangeNotifier {
  final ScanService _scanService = ScanService();
  final ScanQuotaService _quotaService = ScanQuotaService();
  final MobileScannerController cameraController = MobileScannerController();

  String? scannedCode;
  Product? product;
  bool isLoading = false;
  bool isScannerPaused = false;
  String? errorMessage;

  /// True when the error is a quota/limit block (drives paywall CTA in UI)
  bool isQuotaBlock = false;

  /// Loading step state for the overlay (drives "Step n / total")
  int loadingStep = 1;

  /// We show AI as a distinct step → 4 total (cert, ingredients, analysis, AI).
  int loadingTotal = 4;

  /// Overlay texts
  String loadingTitle = 'Checking product…';
  String loadingSubtitle = 'Certification, ingredients (OFF → OCR), analysis';

  /// Optional short label shown under "Step n of m" (e.g., "Reading label…")
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

    // ─── Quota check (same for guest + free users) ───
    final quotaError = await _quotaService.checkQuota();
    if (quotaError != null) {
      scannedCode = barcode;
      isScannerPaused = true;
      errorMessage = quotaError;
      isQuotaBlock = true;
      product = null;
      notifyListeners();
      try { await cameraController.stop(); } catch (_) {}
      return;
    }

    scannedCode = barcode;
    isScannerPaused = true;
    isLoading = true;
    errorMessage = null;
    isQuotaBlock = false;
    product = null;

    // Init overlay with a neutral default
    loadingStep = 1;
    loadingTotal = 4;
    loadingTitle = 'Checking product…';
    loadingSubtitle = 'Certification, ingredients (OFF → OCR), analysis';
    loadingPhaseLabel = null;
    notifyListeners();

    // Stop camera immediately to avoid multiple detections of the same code
    try {
      await cameraController.stop();
    } catch (e) {
      if (kDebugMode) debugPrint("Error stopping camera after detection: $e");
    }

    final firebaseUid = FirebaseAuth.instance.currentUser?.uid;

    try {
      final scannedProduct = await _scanService.scanProduct(
        barcode,
        firebaseUid: firebaseUid,
        onPhase: (title, {String? subtitle, int? step, int? total}) {
          if (step != null) loadingStep = step;
          if (total != null) loadingTotal = total;
          loadingTitle = title;
          if (subtitle != null) loadingSubtitle = subtitle;
          loadingPhaseLabel = title;
          isLoading = true;
          notifyListeners();
        },
      );

      if (scannedProduct != null) {
        product = scannedProduct;

        if (scannedProduct.analysisSteps.isNotEmpty) {
          loadingTotal = scannedProduct.analysisSteps.length;
        }

        errorMessage = null;

        // Record successful scan for quota tracking
        await _quotaService.recordScan();
      } else {
        product = null;
        errorMessage = "Product not found or server error";
      }
    } on ScanException catch (e) {
      product = null;
      errorMessage = e.message;
    } catch (e) {
      product = null;
      errorMessage = "Something went wrong. Please try again.";
    } finally {
      _stepperTimer?.cancel();
      isLoading = false;
      loadingPhaseLabel = null;
      notifyListeners();
    }
  }

  /// Reset scanner state and allow scanning again
  void resetScan() {
    scannedCode = null;
    product = null;
    errorMessage = null;
    isQuotaBlock = false;
    isScannerPaused = false;

    _stepperTimer?.cancel();
    loadingStep = 1;
    loadingTotal = 4;
    loadingTitle = 'Checking product…';
    loadingSubtitle = 'Certification, ingredients (OFF → OCR), analysis';
    loadingPhaseLabel = null;

    notifyListeners();

    Future(() async {
      await _restartCamera();
    });
  }

  /// Retry the last failed scan without reopening the camera
  Future<void> retryScan() async {
    final lastCode = scannedCode;
    if (lastCode == null) return;

    _scanService.resetBackendCheck();

    errorMessage = null;
    isQuotaBlock = false;
    product = null;
    isScannerPaused = false; // allow handleScan to proceed
    notifyListeners();

    await handleScan(lastCode);
  }

  /// Clear any cached products (useful on logout or session reset)
  void clearCache() {
    _scanService.clearCache();
    notifyListeners();
  }

  Future<void> _safeStop() async {
    try { await cameraController.stop(); } catch (_) {}
  }

  Future<void> _safeStart() async {
    try { await cameraController.start(); } catch (e) {
      if (kDebugMode) debugPrint("Error starting camera: $e");
    }
  }

  Future<void> _restartCamera() async {
    await _safeStop();
    await Future.delayed(const Duration(milliseconds: 200));
    await _safeStart();
  }

  void stopCamera() { _safeStop(); }

  @override
  void dispose() {
    _stepperTimer?.cancel();
    stopCamera();
    cameraController.dispose();
    torchState.dispose();
    super.dispose();
  }
}
