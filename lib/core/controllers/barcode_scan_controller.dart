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
  }

  /// Clear any cached products (useful on logout or session reset)
  void clearCache() {
    _scanService.clearCache();
    notifyListeners();
  }

  /// Optional: Stop the camera before disposing controller
  void stopCamera() {
    try {
      cameraController.stop();
    } catch (_) {
      // No-op if already stopped
    }
  }

  @override
  void dispose() {
    stopCamera();
    cameraController.dispose();
    torchState.dispose();
    super.dispose();
  }
}
