import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

import 'package:ummaly/core/controllers/barcode_scan_controller.dart';
import 'package:ummaly/features/scanner/widgets/product_card.dart';
import 'package:ummaly/features/scanner/widgets/scanner_overlay.dart';
import 'package:ummaly/features/scanner/scan_history_screen.dart';
import 'package:ummaly/theme/styles.dart';

class BarcodeScanScreen extends StatefulWidget {
  const BarcodeScanScreen({Key? key}) : super(key: key);

  @override
  State<BarcodeScanScreen> createState() => _BarcodeScanScreenState();
}

class _BarcodeScanScreenState extends State<BarcodeScanScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
      lowerBound: 0.9,
      upperBound: 1.1,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BarcodeScanController(),
      child: Consumer<BarcodeScanController>(
        builder: (context, controller, _) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              title: const Text("Scan Product"),
              backgroundColor: AppColors.scanner,
              actions: [
                /// ✅ History button
                IconButton(
                  icon: const Icon(Icons.history),
                  tooltip: "View Scan History",
                  onPressed: () {
                    final String firebaseUid =
                        FirebaseAuth.instance.currentUser?.uid ?? '';
                    if (firebaseUid.isNotEmpty) {
                      Get.to(() => ScanHistoryScreen(firebaseUid: firebaseUid));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('You need to log in first')),
                      );
                    }
                  },
                ),

                /// ✅ Torch toggle (using our manual torchState tracker)
                ValueListenableBuilder<TorchState>(
                  valueListenable: controller.torchState,
                  builder: (context, state, _) {
                    final isTorchOn = state == TorchState.on;
                    return IconButton(
                      icon: Icon(
                        isTorchOn ? Icons.flash_on : Icons.flash_off,
                        color: isTorchOn ? Colors.yellow : Colors.white,
                      ),
                      onPressed: controller.toggleTorch,
                    );
                  },
                ),
              ],
            ),
            body: Stack(
              children: [
                /// ✅ Camera view
                MobileScanner(
                  controller: controller.cameraController,
                  fit: BoxFit.cover,
                  onDetect: (BarcodeCapture capture) {
                    if (controller.isScannerPaused) return;

                    final List<Barcode> barcodes = capture.barcodes;
                    final Uint8List? image = capture.image;

                    if (barcodes.isNotEmpty) {
                      final String? code = barcodes.first.rawValue;
                      if (code != null && code != controller.scannedCode) {
                        controller.handleScan(code);
                      }
                    }
                  },
                ),

                /// ✅ Overlay (guide box + footer)
                ScannerOverlay(pulseController: _pulseController),

                /// ✅ Loading spinner
                if (controller.isLoading)
                  const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),

                /// ✅ Product card or error card
                ProductCard(
                  productData: controller.productData,
                  errorMessage: controller.errorMessage,
                  onScanAgain: controller.resetScan,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
