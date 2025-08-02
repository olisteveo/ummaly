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

  /// ✅ Track torch state manually since MobileScanner 7.x removed getter
  final ValueNotifier<TorchState> torchState = ValueNotifier(TorchState.off);

  /// ✅ Toggle torch and update state manually
  Future<void> toggleTorch() async {
    await cameraController.toggleTorch();
    // 🔥 Flip our own state since we can't read it from MobileScanner anymore
    torchState.value =
    (torchState.value == TorchState.on) ? TorchState.off : TorchState.on;
    notifyListeners();
  }

  /// ✅ Handle barcode detection
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
      errorMessage = "❌ Product not found or server error";
    }

    isLoading = false;
    notifyListeners();
  }

  /// ✅ Reset scanner
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
    torchState.dispose();
    super.dispose();
  }
}
