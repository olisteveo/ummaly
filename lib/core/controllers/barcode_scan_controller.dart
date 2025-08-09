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

    final product = await _scanService.scanProduct(
      barcode,
      firebaseUid: firebaseUid,
    );

    if (product != null) {
      productData = product.toJson();
    } else {
      errorMessage = "Product not found or server error";
    }

    isLoading = false;
    notifyListeners();
  }

  /// Reset scanner state and allow scanning again
  void resetScan() {
    scannedCode = null;
    productData = null;
    errorMessage = null;
    isScannerPaused = false;
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
    // Note: resetAutoFocus() not available in current MobileScanner, removed.
  }

  /// Optional: Stop the camera before disposing controller
  void stopCamera() {
    _safeStop();
  }

  @override
  void dispose() {
    stopCamera();
    cameraController.dispose();
    torchState.dispose();
    super.dispose();
  }
}
