import 'package:flutter/foundation.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:ummaly/core/services/scan_service.dart';

/// Handles all barcode scanning logic:
/// - Talking to ScanService
/// - Managing torch
/// - Tracking scan state (loading, paused, product info, etc.)
class BarcodeScanController extends ChangeNotifier {
  final ScanService _scanService = ScanService();
  final MobileScannerController cameraController = MobileScannerController();

  String? scannedCode;
  Map<String, dynamic>? productData;
  bool isLoading = false;
  bool isScannerPaused = false;
  String? errorMessage;

  /// Toggles the camera torch on/off
  void toggleTorch() {
    cameraController.toggleTorch();
  }

  /// Handles barcode detection
  Future<void> handleScan(String barcode) async {
    if (isScannerPaused) return;

    scannedCode = barcode;
    isScannerPaused = true;
    isLoading = true;
    errorMessage = null;
    productData = null;
    notifyListeners();

    final product = await _scanService.scanProduct(barcode);

    if (product != null) {
      productData = product.toJson();
    } else {
      errorMessage = "❌ Product not found or server error";
    }

    isLoading = false;
    notifyListeners();
  }

  /// Resets the scanner so the user can scan again
  void resetScan() {
    scannedCode = null;
    productData = null;
    errorMessage = null;
    isScannerPaused = false;
    notifyListeners();
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }
}
